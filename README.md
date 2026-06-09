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

## Cloudflare Tunnels

The workspace now supports managing multiple Cloudflare tunnels through a reusable module (`modules/cloudflare-tunnel`) and one map variable, `cloudflare_tunnels`.

### Google credentials (explicit service key JSON)

The workspace now uses explicit Google credentials instead of environment auto-detection. Set `google_credentials_tunnel_key_json` with the raw service account JSON (commonly via `file()` in your tfvars):

```hcl
google_credentials_tunnel_key_json = file("/path/to/service-account.json")
secret_manager_project_id         = "gcp-project-for-tunnel-secrets"
```

Example service account roles needed for secret writes:
- Secret Manager Secret Admin (or create/access specific secret/version permissions)
- Secret Manager Secret Version Adder

### Example 1: two tunnels (inline Terraform block)

```hcl
cloudflare_tunnels = {
  web = {
    name              = "tf-web-tunnel"
    dns_record_name   = "web"
    service           = "http://127.0.0.1:8080"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-web-token"
    proxied           = true
  }

  admin = {
    name              = "tf-admin-tunnel"
    dns_record_name   = "admin"
    service           = "http://127.0.0.1:9000"
    create_gcp_secret = false
    proxied           = true
  }
}
```

### Example 2: two tunnels from `terraform.tfvars`

```hcl
cloudflare_tunnels = {
  api = {
    name              = "api-tunnel"
    dns_record_name   = "api"
    service           = "http://127.0.0.1:9001"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-api-token"
    proxied           = true
  }

  logs = {
    name              = "logs-tunnel"
    dns_record_name   = "logs"
    service           = "https://10.0.0.20:9200"
    create_gcp_secret = true
    proxied           = true
  }
}
```

Example input:

```hcl
cloudflare_tunnels = {
  keycloak = {
    name             = "keycloak-tunnel"
    dns_record_name  = "keycloak"
    service          = "http://127.0.0.1:8080"
    secret           = ""     # optional, omitted/blank generates automatically
    proxied          = true
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-keycloak-token"
  }
  openobserve = {
    name             = "openobserve-tunnel"
    dns_record_name  = "openobserve"
    service          = "http://127.0.0.1:5080"
    create_gcp_secret = true
    secret           = ""
  }
  another = {
    name            = "another-tunnel"
    dns_record_name = "another"
    service         = "http://127.0.0.1:9000"
    create_gcp_secret = false
  }
}
```

Set the global `domain` variable once (for example, `example.com`) and Terraform will build each tunnel `public_hostname` as:

`dns_record_name == "@" ? domain : "${dns_record_name}.${domain}"`

Outputs are keyed by the map key:
- `cloudflare_tunnel_ids`
- `cloudflare_tunnel_names`
- `cloudflare_tunnel_cnames`
- `cloudflare_tunnel_tokens` (sensitive)
- `cloudflare_tunnel_secret_ids` (Secret Manager secret name)
- `cloudflare_tunnel_secret_version_ids` (Secret Manager version resource IDs)
- `cloudflare_tunnel_secret_enabled` (boolean)

### Synthetic Vault sync events

If you want tunnel secret creation to be picked up by the existing Vault sync pipeline without changing its handler code, enable the synthetic event path in your active `terraform.tfvars` (or a `*.auto.tfvars` file):

```hcl
emit_tunnel_secret_sync_events = true
vault_sync_event_url          = "https://vault-sync-run-container-<hash>-<ns>.run.app"
vault_sync_event_token        = "optional_bearer_token"
vault_sync_event_fallback_sync_all = false

# Optional: if true and the direct synthetic payload post fails, run POST /sync-all
# to force a full resync from vault-sync's side.
```

Setting just `vault_sync_event_url` to a non-empty value is also enough to enable emission.

Terraform only auto-loads `terraform.tfvars` and `*.auto.tfvars`; other filenames (such as `cloudflare-tunnels.tfvars`) are ignored unless you pass `-var-file`.

When enabled, the tunnel module posts a single JSON event per created secret version directly to the endpoint using:
- `protoPayload.methodName = google.cloud.secretmanager.v1.SecretManagerService.AddSecretVersion`
- `protoPayload.resourceName = projects/<project>/secrets/<secret_name>/versions/<version>`

No CloudEvent headers are required for this path; this maps to the service’s manual direct JSON normalization path.

Keep this disabled unless your endpoint is intentionally accepting synthetic events, since it runs a `local-exec` in Terraform during apply.
