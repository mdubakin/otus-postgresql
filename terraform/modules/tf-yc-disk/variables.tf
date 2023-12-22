variable "secondary_disks_count" {
  type        = number
  description = "How many disks to create"
}

variable "name" {
  type        = string
  default     = "secondary"
  description = "How many disks to create"
}

variable "zone" {
  type        = string
  description = "Yandex Cloud availability zone"
}

variable "type" {
  type        = string
  default     = "network-hdd"
  description = "Disk type"
}

variable "size" {
  type        = number
  default     = 10
  description = "Size of disk"
}
