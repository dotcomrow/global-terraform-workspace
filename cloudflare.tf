resource "cloudflare_workers_kv_namespace" "CONFIG" {
  account_id = var.cloudflare_account_id
  title      = "CONFIG"
}

resource "cloudflare_workers_kv" "CACHE_NAME" {
  account_id   = var.cloudflare_account_id
  namespace_id = cloudflare_workers_kv_namespace.CONFIG.id
  key          =  "CACHE_NAME"
  value        =  "URL_MAP"
}

resource "cloudflare_workers_kv" "MAX_AGE" {
  account_id   = var.cloudflare_account_id
  namespace_id = cloudflare_workers_kv_namespace.CONFIG.id
  key          =  "MAX_AGE"
  value        =  var.cloudflare_cache_max_age
}

resource "cloudflare_workers_kv" "CORS_DOMAINS" {
  account_id   = var.cloudflare_account_id
  namespace_id = cloudflare_workers_kv_namespace.CONFIG.id
  key          =  "CORS_DOMAINS"
  value        =  var.cloudflare_cors_domains
}