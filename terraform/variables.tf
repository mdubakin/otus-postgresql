variable "zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Default availability zone"
}

variable "folder_id" {
  type    = string
  default = "b1ghu0t9369oubljv78j"
}

variable "name" {
  type        = string
  default     = "otus-postgresql"
  description = "VM name"
}

variable "os_family" {
  type        = string
  default     = "ubuntu-2204-lts"
  description = "OS famliy"
}

