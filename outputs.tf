// Outputs

output "external_ip_address_pcs-server" {
  value = [yandex_compute_instance.pcs-server[*].hostname, yandex_compute_instance.pcs-server[*].network_interface.0.nat_ip_address]
}

output "internal_ip_address_pcs-server" {
  value = [yandex_compute_instance.pcs-server[*].hostname, yandex_compute_instance.pcs-server[*].network_interface.0.ip_address]
}

output "external_ip_address_iscsi-servers" {
  value = [yandex_compute_instance.iscsi-servers[*].hostname, yandex_compute_instance.iscsi-servers[*].network_interface.0.nat_ip_address]
}

output "internal_ip_address_iscsi-servers" {
  value = [yandex_compute_instance.iscsi-servers[*].hostname, yandex_compute_instance.iscsi-servers[*].network_interface.0.ip_address]
}

// Outputs