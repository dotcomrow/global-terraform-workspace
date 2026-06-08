
cloudflare_tunnels = {
  graphql = {
    name              = "graphql-origin-tunnel"
    dns_record_name   = "graphql-origin-tunnel"
    service           = "http://hasura.graphql.svc.cluster.local:8080"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-graphql-token"
    proxied           = true
  }

  keycloak = {
    name              = "keycloak-origin-tunnel"
    dns_record_name   = "auth-origin-tunnel"
    service           = "http://keycloak.keycloak.svc.cluster.local:8080"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-keycloak-token"
    proxied           = true
  }

  openobserve = {
    name              = "openobserve-origin-tunnel"
    dns_record_name   = "openobserve-origin-tunnel"
    service           = "http://openobserve-router.openobserve.svc.cluster.local:5080"
    create_gcp_secret = true
    gcp_secret_id     = "cloudflare-tunnel-openobserve-token"
    proxied           = true
  }
}
