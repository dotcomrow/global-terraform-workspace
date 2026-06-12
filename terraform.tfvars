emit_tunnel_secret_sync_events = true
vault_sync_event_fallback_sync_all = true
vault_sync_service_project       = "tf-k8s-cluster-infra-9734"
vault_sync_service_region        = "us-east1"
vault_sync_service_name          = "vault-sync-run-container"
# vault_sync_grant_invoker_binding = false
# vault_sync_invoker_service_account = "eventarc-vault-sync@tf-k8s-cluster-infra-9734.iam.gserviceaccount.com"
# vault_sync_event_url = "https://vault-sync-run-container-...-uc.a.run.app"
# vault_sync_event_token = "" # optional bearer token if required by Cloud Run auth

cloudflare_tunnels = {
  graphql = {
    name              = "graphql-origin-tunnel"
    dns_record_name   = "graphql-origin"
    service           = "http://hasura.graphql.svc.cluster.local:8080"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-graphql-token"
    proxied           = true
  }

  keycloak = {
    name              = "keycloak-origin-tunnel"
    dns_record_name   = "auth-origin"
    service           = "http://keycloak.keycloak.svc.cluster.local:8080"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-keycloak-token"
    proxied           = true
  }

  openobserve = {
    name              = "openobserve-origin-tunnel"
    dns_record_name   = "openobserve-origin"
    service           = "http://openobserve-router.openobserve.svc.cluster.local:5080"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-openobserve-token"
    proxied           = true
  }
}
