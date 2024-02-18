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

# resource "cloudflare_logpush_job" "workers_trace_events" {
#   enabled          = true
#   zone_id          = var.cloudflare_zone_id
#   name             = "workers-trace-events"
#   logpull_options  = "fields=DispatchNamespace,Event,EventTimestampMs,EventType,Exceptions,Logs,Outcome,ScriptName,ScriptTags&timestamps=rfc3339"
#   destination_conf = "r2://cloudflare-logs/workers_trace_events/date={DATE}?account-id=${var.cloudflare_account_id}&access-key-id=${var.cloudflare_logs_access_key}&secret-access-key=${var.cloudflare_logs_access_secret}"
#   dataset          = "workers_trace_events"
# }

