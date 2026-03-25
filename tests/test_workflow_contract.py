import pathlib
import re
import unittest

import yaml


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
WORKFLOW_DIR = REPO_ROOT / ".github" / "workflows"
WORKFLOW_FILES = sorted(WORKFLOW_DIR.glob("*.yaml"))
FULL_SHA_PATTERN = re.compile(r"^[0-9a-f]{40}$")
PIN_KEY_PATTERN = re.compile(r"^SECURE_PACKER_BOOTSTRAPPER_RELEASE_[A-Z0-9_]+=")


def load_workflow(path: pathlib.Path):
    return yaml.load(path.read_text(encoding="utf-8"), Loader=yaml.BaseLoader)


def iter_steps(container):
    for step in container.get("steps", []):
        yield step


def iter_jobs(document):
    for job_name, job in document.get("jobs", {}).items():
        yield job_name, job


class WorkflowContractTests(unittest.TestCase):
    def test_workflow_yaml_files_parse(self):
        for workflow_path in WORKFLOW_FILES:
            with self.subTest(workflow=workflow_path.name):
                self.assertIsInstance(load_workflow(workflow_path), dict)

    def test_all_jobs_have_explicit_timeouts(self):
        for workflow_path in WORKFLOW_FILES:
            workflow = load_workflow(workflow_path)
            for job_name, job in iter_jobs(workflow):
                with self.subTest(workflow=workflow_path.name, job=job_name):
                    self.assertIn("timeout-minutes", job)

    def test_every_checkout_step_disables_persisted_credentials(self):
        for workflow_path in WORKFLOW_FILES:
            workflow = load_workflow(workflow_path)
            for job_name, job in iter_jobs(workflow):
                for step in iter_steps(job):
                    if step.get("uses", "").startswith("actions/checkout@"):
                        with self.subTest(workflow=workflow_path.name, job=job_name, step=step.get("name")):
                            self.assertEqual(str(step.get("with", {}).get("persist-credentials")).lower(), "false")

    def test_all_actions_are_pinned_to_full_commit_shas(self):
        for workflow_path in WORKFLOW_FILES:
            workflow = load_workflow(workflow_path)
            for job_name, job in iter_jobs(workflow):
                for step in iter_steps(job):
                    uses = step.get("uses")
                    if not uses:
                        continue
                    ref = uses.split("@", 1)[1]
                    with self.subTest(workflow=workflow_path.name, job=job_name, uses=uses):
                        self.assertRegex(ref, FULL_SHA_PATTERN)

    def test_workflows_define_explicit_permissions(self):
        for workflow_path in WORKFLOW_FILES:
            workflow = load_workflow(workflow_path)
            top_permissions = workflow.get("permissions")
            for job_name, job in iter_jobs(workflow):
                with self.subTest(workflow=workflow_path.name, job=job_name):
                    self.assertTrue(top_permissions is not None or job.get("permissions") is not None)

    def test_packer_workflow_is_restricted_to_trusted_main_builds(self):
        workflow = load_workflow(WORKFLOW_DIR / "packer.yaml")
        self.assertNotIn("pull_request", workflow["on"])
        self.assertIn("workflow_dispatch", workflow["on"])
        self.assertEqual(workflow["on"]["push"]["branches"], ["main"])
        self.assertIn("pin-preflight", workflow["jobs"])

        packer_job = workflow["jobs"]["packer"]
        self.assertEqual(packer_job["needs"], "pin-preflight")
        self.assertEqual(packer_job["environment"], "packer-build")
        self.assertIn("self-hosted", packer_job["runs-on"])

    def test_pr_verify_runs_unit_tests_before_repo_gates(self):
        workflow = load_workflow(WORKFLOW_DIR / "pr-verify.yaml")
        self.assertIn("merge_group", workflow["on"])
        step_names = [step.get("name") for step in workflow["jobs"]["validate"]["steps"]]
        self.assertIn("Run actionlint", step_names)
        self.assertIn("Run Automation Unit Tests", step_names)
        self.assertLess(step_names.index("Run Automation Unit Tests"), step_names.index("Run Repo-Local Gates"))
        self.assertLess(step_names.index("Run actionlint"), step_names.index("Run Repo-Local Gates"))

    def test_security_and_codeql_support_merge_group(self):
        for workflow_name in ["security.yaml", "codeql.yaml"]:
            workflow = load_workflow(WORKFLOW_DIR / workflow_name)
            with self.subTest(workflow=workflow_name):
                self.assertIn("merge_group", workflow["on"])

    def test_required_status_check_names_remain_stable(self):
        security_workflow = load_workflow(WORKFLOW_DIR / "security.yaml")
        codeql_workflow = load_workflow(WORKFLOW_DIR / "codeql.yaml")

        self.assertEqual(security_workflow["jobs"]["trivy"]["name"], "Trivy (Filesystem & Secrets)")
        self.assertEqual(security_workflow["jobs"]["gitleaks"]["name"], "Gitleaks (Secret Scan)")
        self.assertEqual(codeql_workflow["jobs"]["analyze"]["name"], "CodeQL (${{ matrix.language }})")

    def test_refresh_workflow_restricts_pull_request_target_writes_to_same_repo_branches(self):
        workflow = load_workflow(WORKFLOW_DIR / "refresh-bootstrapper-pin.yaml")
        sync_job_if = workflow["jobs"]["sync-pr-branch"]["if"]
        self.assertIn("github.event.pull_request.head.repo.full_name == github.repository", sync_job_if)
        self.assertIn("github.actor != 'github-actions[bot]'", sync_job_if)

    def test_pin_file_is_structurally_consistent(self):
        pin_file = REPO_ROOT / ".github" / "pins" / "secure-packer-bootstrapper.env"
        lines = [line.strip() for line in pin_file.read_text(encoding="utf-8").splitlines() if line.strip()]
        assignments = [line for line in lines if PIN_KEY_PATTERN.match(line)]
        self.assertEqual(len(assignments), 6)

        values = {}
        for assignment in assignments:
            key, value = assignment.split("=", 1)
            values[key] = value

        required_keys = {
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_REPO",
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_TAG",
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_URL",
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256",
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256_URL",
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_METADATA_URL",
        }
        self.assertEqual(set(values), required_keys)
        self.assertEqual(values["SECURE_PACKER_BOOTSTRAPPER_RELEASE_REPO"], "NWarila/secure-packer-bootstrapper")

        tracked_values = [
            values["SECURE_PACKER_BOOTSTRAPPER_RELEASE_TAG"],
            values["SECURE_PACKER_BOOTSTRAPPER_RELEASE_URL"],
            values["SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256"],
            values["SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256_URL"],
            values["SECURE_PACKER_BOOTSTRAPPER_RELEASE_METADATA_URL"],
        ]
        all_empty = all(value == "" for value in tracked_values)
        all_present = all(value != "" for value in tracked_values)
        self.assertTrue(all_empty or all_present)


if __name__ == "__main__":
    unittest.main()
