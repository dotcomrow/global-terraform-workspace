resource "cloudflare_ruleset" "zone_rl" {
  zone_id     = var.cloudflare_zone_id
  name        = "Advanced rate limiting rule *"
  description = "DDOS and cost protection for *"
  kind        = "zone"
  phase       = "http_ratelimit"

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
      requests_per_period = 10
      mitigation_timeout = 10
    }
    expression = "(http.request.uri.path contains \"/\")"
    description = "Rate limit requests to *"
    enabled = true
  }
}

