terraform {
  cloud {
    organization = "<ORGANIZATION_ID>"

    workspaces {
      name = "<WORKSPACE_NAME>"
    }
  }
}