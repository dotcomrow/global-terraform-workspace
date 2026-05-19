# template-terraform-workspace
Template repository for Terraform project for GCP microservice stack

## Usage
requires GCP project to be created and terraform cloud id

## GitHub Actions Allowlist
This workspace can automatically fetch GitHub Actions runner CIDR ranges from `https://api.github.com/meta` and add them to an account-level Cloudflare IP list (default: `github_actions_runners`, configurable via `github_actions_cloudflare_list_name`).

The synchronization is optional and enabled by default (`enable_github_actions_allowlist = true`).

To keep Terraform plans responsive, list entries are synchronized through Cloudflare's asynchronous bulk list API after Terraform ensures the list resource exists.

When `enable_github_actions_allowlist = true`, this workspace can also upsert a custom WAF skip rule (enabled by default) into the existing `http_request_firewall_custom` entrypoint ruleset to skip Cloudflare firewall/rate-limiting checks for requests matching:
- `http.host` in `{ github_actions_bypass_host, "auth-origin.suncoast.systems" }` (default primary host is `login.suncoast.systems`)
- `http.request.uri.path` starts with `github_actions_bypass_path_prefix` (default `/v1/apps`)
- `ip.src` in the synchronized GitHub Actions list

## Scheduled Sync
A GitHub Actions workflow is included at `.github/workflows/sync-github-actions-allowlist.yml` to run `terraform apply` on a schedule and refresh the GitHub Actions CIDR list automatically.
