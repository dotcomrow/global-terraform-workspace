data "http" "github_meta" {
  count = var.enable_github_actions_allowlist ? 1 : 0

  url = var.github_meta_api_url

  request_headers = {
    Accept               = "application/vnd.github+json"
    X-GitHub-Api-Version = var.github_meta_api_version
  }
}

locals {
  github_actions_list_name = var.github_actions_cloudflare_list_name

  github_actions_runner_cidrs = var.enable_github_actions_allowlist ? sort(distinct([
    for cidr in try(jsondecode(data.http.github_meta[0].response_body).actions, []) :
    trimspace(cidr)
    if trimspace(cidr) != ""
  ])) : []

  github_actions_list_reference = length(local.github_actions_runner_cidrs) > 0 ? format("$%s", local.github_actions_list_name) : ""

  global_rate_limit_expression = local.github_actions_list_reference != "" ?
  "(http.request.uri.path contains \"/\" and not (ip.src in ${local.github_actions_list_reference}))" :
  "(http.request.uri.path contains \"/\")"
}

resource "cloudflare_list" "github_actions_runners" {
  count = var.enable_github_actions_allowlist ? 1 : 0

  account_id  = var.cloudflare_account_id
  kind        = "ip"
  name        = local.github_actions_list_name
  description = "GitHub Actions hosted runner CIDRs from ${var.github_meta_api_url}"

  items = [
    for cidr in local.github_actions_runner_cidrs : {
      ip      = cidr
      comment = "GitHub Actions hosted runner CIDR"
    }
  ]

  lifecycle {
    precondition {
      condition     = length(local.github_actions_runner_cidrs) > 0
      error_message = "GitHub meta API returned no Actions CIDR ranges."
    }
  }
}
