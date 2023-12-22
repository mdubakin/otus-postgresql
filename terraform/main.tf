module "compute_instance" {
  source         = "./modules/tf-yc-instance"
  subnet_id      = module.network.yandex_vpc_subnets[var.zone]
  name           = var.name
  zone           = var.zone
  os_family      = var.os_family
  boot_disk_size = 20
}

module "network" {
  source = "./modules/tf-yc-network"
}

module "s3_bucket" {
  source      = "./modules/tf-yc-s3"
  folder_id   = var.folder_id
  sa_name     = "otus-postgresql"
  bucket_name = "tfstate-otus-postgresql"
}
