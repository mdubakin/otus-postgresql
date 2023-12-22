output "sa_access_key" {
  value     = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  sensitive = true
}

output "sa_secret_key" {
  value     = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive = true
}
