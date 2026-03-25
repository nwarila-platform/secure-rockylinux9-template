import contextlib
import importlib.util
import io
import pathlib
import shutil
import unittest
import uuid
from unittest import mock


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT_PATH = REPO_ROOT / ".github" / "scripts" / "refresh_secure_packer_bootstrapper_pin.py"


def load_module():
    spec = importlib.util.spec_from_file_location("refresh_secure_packer_bootstrapper_pin", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def make_scratch_dir() -> pathlib.Path:
    scratch_dir = REPO_ROOT / "tests" / ".tmp" / uuid.uuid4().hex
    scratch_dir.mkdir(parents=True, exist_ok=False)
    return scratch_dir


class RefreshSecurePackerBootstrapperPinTests(unittest.TestCase):
    def setUp(self):
        self.module = load_module()

    def test_parse_checksum_accepts_sha256_prefix(self):
        checksum = self.module.parse_checksum(
            "2FD1149C5C6C7604CED64D7B56638AF05F6B7ED3F6835182BC913DDABA1F16B8  bundle.sh\n"
        )
        self.assertEqual(checksum, "2fd1149c5c6c7604ced64d7b56638af05f6b7ed3f6835182bc913ddaba1f16b8")

    def test_parse_checksum_rejects_invalid_content(self):
        with self.assertRaises(ValueError):
            self.module.parse_checksum("not-a-checksum bundle.sh\n")

    def test_validate_release_asset_url_rejects_untrusted_shape(self):
        with self.assertRaises(ValueError):
            self.module.validate_release_asset_url(
                "http://example.com/bundle.sh",
                "NWarila/secure-packer-bootstrapper",
                "v1.2.3",
                "secure-packer-bootstrapper.sh",
            )

    def test_main_writes_refreshed_pin_file(self):
        release = {
            "tag_name": "v1.2.3",
            "assets": [
                {
                    "name": "secure-packer-bootstrapper.sh",
                    "browser_download_url": "https://github.com/NWarila/secure-packer-bootstrapper/releases/download/v1.2.3/secure-packer-bootstrapper.sh",
                },
                {
                    "name": "secure-packer-bootstrapper.sh.sha256",
                    "browser_download_url": "https://github.com/NWarila/secure-packer-bootstrapper/releases/download/v1.2.3/secure-packer-bootstrapper.sh.sha256",
                },
                {
                    "name": "secure-packer-bootstrapper.release.json",
                    "browser_download_url": "https://github.com/NWarila/secure-packer-bootstrapper/releases/download/v1.2.3/secure-packer-bootstrapper.release.json",
                },
            ],
        }

        scratch_dir = make_scratch_dir()
        self.addCleanup(lambda: shutil.rmtree(scratch_dir, ignore_errors=True))
        output_path = scratch_dir / "secure-packer-bootstrapper.env"
        stdout = io.StringIO()
        stderr = io.StringIO()
        argv = [
            str(SCRIPT_PATH),
            "--repo",
            "NWarila/secure-packer-bootstrapper",
            "--output",
            str(output_path),
            "--write",
        ]
        with mock.patch.object(self.module, "fetch_json", return_value=release), mock.patch.object(
            self.module,
            "fetch_text",
            return_value="d34db33fd34db33fd34db33fd34db33fd34db33fd34db33fd34db33fd34db33f  secure-packer-bootstrapper.sh\n",
        ), mock.patch("sys.argv", argv), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = self.module.main()

        self.assertEqual(exit_code, 0)
        self.assertEqual(stderr.getvalue(), "")
        rendered = output_path.read_text(encoding="utf-8")
        self.assertIn("SECURE_PACKER_BOOTSTRAPPER_RELEASE_TAG=v1.2.3", rendered)
        self.assertIn(
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_URL=https://github.com/NWarila/secure-packer-bootstrapper/releases/download/v1.2.3/secure-packer-bootstrapper.sh",
            rendered,
        )
        self.assertIn(
            "SECURE_PACKER_BOOTSTRAPPER_RELEASE_SHA256=d34db33fd34db33fd34db33fd34db33fd34db33fd34db33fd34db33fd34db33f",
            rendered,
        )

    def test_main_allows_missing_release_when_configured(self):
        scratch_dir = make_scratch_dir()
        self.addCleanup(lambda: shutil.rmtree(scratch_dir, ignore_errors=True))
        output_path = scratch_dir / "secure-packer-bootstrapper.env"
        stdout = io.StringIO()
        stderr = io.StringIO()
        argv = [
            str(SCRIPT_PATH),
            "--repo",
            "NWarila/secure-packer-bootstrapper",
            "--output",
            str(output_path),
            "--check",
            "--allow-missing-release",
        ]
        with mock.patch.object(self.module, "fetch_json", return_value=None), mock.patch(
            "sys.argv", argv
        ), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = self.module.main()

        self.assertEqual(exit_code, 0)
        self.assertIn("No published release found", stdout.getvalue())
        self.assertEqual(stderr.getvalue(), "")

    def test_main_fails_when_required_assets_are_missing(self):
        release = {
            "tag_name": "v1.2.3",
            "assets": [
                {
                    "name": "secure-packer-bootstrapper.sh",
                    "browser_download_url": "https://github.com/NWarila/secure-packer-bootstrapper/releases/download/v1.2.3/secure-packer-bootstrapper.sh",
                }
            ],
        }

        scratch_dir = make_scratch_dir()
        self.addCleanup(lambda: shutil.rmtree(scratch_dir, ignore_errors=True))
        output_path = scratch_dir / "secure-packer-bootstrapper.env"
        stdout = io.StringIO()
        stderr = io.StringIO()
        argv = [
            str(SCRIPT_PATH),
            "--repo",
            "NWarila/secure-packer-bootstrapper",
            "--output",
            str(output_path),
            "--check",
        ]
        with mock.patch.object(self.module, "fetch_json", return_value=release), mock.patch(
            "sys.argv", argv
        ), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = self.module.main()

        self.assertEqual(exit_code, 1)
        self.assertIn("missing required assets", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
