output "sa_access_key" {
  value     = module.s3_bucket.sa_access_key
  sensitive = true
}

output "sa_secret_key" {
  value     = module.s3_bucket.sa_secret_key
  sensitive = true
}

output "ip_address_external" {
  value = module.compute_instance.ip_address_external
}

output "secondary_disks_ids" {
  value = module.disk.ids
}
