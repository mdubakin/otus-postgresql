variable "network_zones" {
  description = "Subnet zones"
  type        = set(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-c"]
}

variable "cloud_id" {
  type    = string
  default = "b1g3jddf4nv5e9okle7p"
}

variable "folder_id" {
  type    = string
  default = "b1gm68de4u794bg8egku"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}
