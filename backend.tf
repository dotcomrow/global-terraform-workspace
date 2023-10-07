terraform {
  cloud {
    organization = "dotcomrow"

    workspaces {
      name = "global-terraform-workspace"
    }
  }
}