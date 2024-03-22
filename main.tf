// Provider configuration

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  required_version = ">= 0.13"
}
provider "yandex" {
  token     = var.access["token"]
  cloud_id  = var.access["cloud_id"]
  folder_id = var.access["folder_id"]
  zone = var.access["zone"]
}
//Provider configuration

//Create Virtual mashine
resource "yandex_compute_instance" "pcs-server" {
  name = "pcs-server${count.index + 1 }"
  count = var.data["count"]
  hostname = "pcs-server-${count.index + 1}"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8p7vi5c5bbs2s5i67s" //Centos 7
      size = 10
      type = "network-ssd"
    }
    
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.pcs-server-subnet-1.id
    nat       = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.iscsi-servers-subnet-2.id
    nat       = false
    ip_address = "10.179.1.20${count.index + 1 }"
  }
  network_interface {
    subnet_id  = yandex_vpc_subnet.iscsi-servers-subnet-3.id
    nat        = false
    ip_address = "10.179.2.20${count.index + 1}"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.pcs-server-subnet-2.id
    nat        = false
    ip_address = "10.179.3.20${count.index + 1}"
  }

  metadata = {
    user-data = "${file("~/Myhomework/otus_hw2/cloud-init.yaml")}"
  }
  depends_on = [
    yandex_compute_instance.iscsi-servers
  ]
}
resource "yandex_compute_instance" "iscsi-servers" {

  name                      = "iscsi-1"
  count                     = 1
  hostname                  = "iscsi-1"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8p7vi5c5bbs2s5i67s" //Centos 7
      size     = 10 
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.iscsi-servers-subnet-1.id
    nat       = true
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.iscsi-servers-subnet-2.id
    nat        = false
    ip_address = "10.179.1.204"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.iscsi-servers-subnet-3.id
    nat        = false
    ip_address = "10.179.2.204"
  }

  secondary_disk {
    disk_id = yandex_compute_disk.iscsi-secondary-data-disk.id
  }

  metadata = {
    user-data = "${file("~/Myhomework/otus_hw2/cloud-init.yaml")}"
  }
}
// Create VM
// Create Networks
resource "yandex_vpc_network" "ru-central1-b-servers-network-1" {
  name = "pcs-network-1"
}
// Create Networks

// Create Subnets
resource "yandex_vpc_subnet" "pcs-server-subnet-1" {
  name           = "pcs-server-subnet-1"
  zone           = var.access["zone"]
  network_id     = yandex_vpc_network.ru-central1-b-servers-network-1.id
  v4_cidr_blocks = ["10.160.0.0/24"]
}

resource "yandex_vpc_subnet" "pcs-server-subnet-2" {
  name           = "pcs-server-subnet-2"
  zone           = var.access["zone"]
  network_id     = yandex_vpc_network.ru-central1-b-servers-network-1.id
  v4_cidr_blocks = ["10.179.3.0/24"]
}

resource "yandex_vpc_subnet" "iscsi-servers-subnet-1" {
  name           = "iscsi-servers-subnet-1"
  zone           = var.access["zone"]
  network_id     = yandex_vpc_network.ru-central1-b-servers-network-1.id
  v4_cidr_blocks = ["10.179.0.0/24"]
}

resource "yandex_vpc_subnet" "iscsi-servers-subnet-2" {
  name           = "iscsi-servers-subnet-2"
  zone           = var.access["zone"]
  network_id     = yandex_vpc_network.ru-central1-b-servers-network-1.id
  v4_cidr_blocks = ["10.179.1.0/24"]
}

resource "yandex_vpc_subnet" "iscsi-servers-subnet-3" {
  name           = "iscsi-servers-subnet-3"
  zone           = var.access["zone"]
  network_id     = yandex_vpc_network.ru-central1-b-servers-network-1.id
  v4_cidr_blocks = ["10.179.2.0/24"]
}

// Create Subnets

// Create secondary disks

resource "yandex_compute_disk" "iscsi-secondary-data-disk" {

  name = "iscsi-secondary-data-disk-01"
  type = "network-hdd"
  zone = var.access["zone"]
  size = "1"
}

// Create secondary disks

// Check SSH connection and output debug message

resource "null_resource" "ansible-install-pcs-server" {

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = format("ansible-playbook -D -i %s, -u ${var.data["account"]} ${path.module}/ansible-provision/accessebility.yml",
      join("\",\"", yandex_compute_instance.pcs-server[*].network_interface.0.nat_ip_address, yandex_compute_instance.iscsi-servers[*].network_interface.0.nat_ip_address)
    )
  }
}

// Check SSH connection and output debug message

// Create hosts file for Ansible

resource "local_file" "hosts_ini" {
  filename = "./ansible-provision/hosts.ini"

  content = <<-EOT
[all]
%{for ip in yandex_compute_instance.iscsi-servers[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
%{for ip in yandex_compute_instance.pcs-server[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
[iscsi_servers]
%{for ip in yandex_compute_instance.iscsi-servers[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
[pcs-servers]
%{for ip in yandex_compute_instance.pcs-server[*].network_interface.0.nat_ip_address~}
${ip}
%{endfor~}
EOT
}




