resource "yandex_compute_disk" "this" {
  count = var.secondary_disks_count
  name  = "${var.name}-disk-${count.index}"
  zone  = var.zone
  type  = var.type
  size  = var.size
}
