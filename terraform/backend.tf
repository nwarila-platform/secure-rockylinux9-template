terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "nwarila-platform"

    workspaces {
      name = "secure-rockylinux9-template-iso"
    }
  }
}
