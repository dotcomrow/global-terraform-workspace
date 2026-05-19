resource "cloudflare_ruleset" "zone_rl" {
  zone_id     = var.cloudflare_zone_id
  name        = "Advanced rate limiting rule *"
  description = "DDOS and cost protection for *"
  kind        = "zone"
  phase       = "http_ratelimit"
  depends_on  = [cloudflare_list.github_actions_runners]

  rules {
    action = "block"
    action_parameters {
      response {
        status_code = 429
        content = "{\"response\": \"To many requests, please wait a moment and try again.\"}"
        content_type = "application/json"
      }
    }
    ratelimit {
      requests_to_origin = "false"
      characteristics = ["ip.src", "cf.colo.id"]
      period = 10
      requests_per_period = 50
      mitigation_timeout = 10
    }
    expression = local.global_rate_limit_expression
    description = "Rate limit requests to *"
    enabled = true
  }
}
