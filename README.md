# template-terraform-workspace
Template repository for Terraform project for GCP microservice stack

## Usage
requires GCP project to be created and terraform cloud id

## GitHub Actions Allowlist
This workspace can automatically fetch GitHub Actions runner CIDR ranges from `https://api.github.com/meta` and add them to an account-level Cloudflare IP list (default: `github_actions_runners`, configurable via `github_actions_cloudflare_list_name`).

The synchronization is optional and disabled by default (`enable_github_actions_allowlist = false`).

To keep Terraform plans responsive, list entries are synchronized through Cloudflare's asynchronous bulk list API after Terraform ensures the list resource exists.
