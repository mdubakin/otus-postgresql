variable "boot_disk_size" {
  type        = number
  description = "Boot size in GB"
  default     = 10
}

variable "secondary_disks_ids" {
  type    = list(string)
  default = []
}

variable "cpu_cores" {
  type        = number
  description = "VCPU Cores"
  default     = 2
}

variable "memory" {
  type        = number
  description = "RAM in GB"
  default     = 2
}

variable "preemptible" {
  type        = bool
  description = "Is preemptible?"
  default     = true
}

variable "platform_id" {
  type    = string
  default = "standard-v3"
}

variable "os_family" {
  type        = string
  description = "OS Family"
  default     = "ubuntu-2004-lts"
}

variable "subnet_id" {
  type = string
}

variable "zone" {
  type = string
}

variable "name" {
  type = string
}

variable "nat" {
  type    = bool
  default = true
}
