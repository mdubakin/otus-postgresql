output "yandex_vpc_network" {
  description = "Yandex.Cloud Subnets map"
  value       = data.yandex_vpc_network.default.subnet_ids
}

output "yandex_vpc_subnets" {
  description = "Yandex.Cloud Subnets map"
  value       = { for subnet in data.yandex_vpc_subnet.default : subnet.zone => subnet.id }
}
