resource "google_identity_platform_oauth_idp_config" "oauth_idp_config" {
  name          = "oidc.oauth-idp-config"
  display_name  = "domain oauth"
  client_id     = "client-id"
  issuer        = "issuer"
  enabled       = true
  client_secret = "secret"
  project =  var.common_project_id
}