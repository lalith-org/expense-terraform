data "vault_generic_secret" "ssh_creds" {
  path = "db/rds"
}