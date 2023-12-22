locals {
  cloud_init_file = "./modules/tf-yc-instance/configs/users.yaml"
}

data "yandex_compute_image" "os" {
  family = var.os_family
}

resource "yandex_compute_instance" "vm-1" {
  name        = var.name
  platform_id = var.platform_id
  zone        = var.zone

  scheduling_policy {
    preemptible = var.preemptible
  }

  resources {
    cores  = var.cpu_cores
    memory = var.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.os.image_id
      size     = var.boot_disk_size
    }
  }

  dynamic "secondary_disk" {
    for_each = length(var.secondary_disks_ids) > 0 ? var.secondary_disks_ids : []
    content {
      disk_id = secondary_disk.value
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = var.nat
  }

  metadata = {
    user-data = "${file(local.cloud_init_file)}"
  }

}
