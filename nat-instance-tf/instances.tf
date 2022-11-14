data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-1804-lts"
}

data "yandex_compute_image" "nat_instance_ubuntu_image" {
  family = "nat-instance-ubuntu"
}



resource "yandex_compute_instance" "test_vm_tf" {
  name = "test-vm-tf"
  zone = yandex_vpc_subnet.nat_instance_private_subnet.zone
 
  resources {
      cores  = 2
      core_fraction = 20
      memory = 1
  }

  scheduling_policy {
      preemptible  = true
  }

  boot_disk {
      initialize_params {
          image_id = data.yandex_compute_image.ubuntu_image.id
          size = 10
      }
  }

  network_interface {
      subnet_id = yandex_vpc_subnet.nat_instance_private_subnet.id 
  }

  metadata = {
      user-data = <<-EOT
        #cloud-config
        ssh_pwauth: 1
        users:
          - name: ${var.default_user}
            lock-passwd: false
            passwd: $1$Y315@9$SdSj0vBsdjA4tyCCO9qpi.
            sudo: ALL=(ALL) NOPASSWD:ALL
            shell: /bin/bash
        EOT
  }

  
}


resource "yandex_compute_instance" "nat_instance_tf" {
  name = "nat-instance-tf"
  zone = yandex_vpc_subnet.nat_instance_public_subnet.zone

 resources {
      cores  = 2
      core_fraction = 20
      memory = 1
  }

  scheduling_policy {
      preemptible  = true
  }

  boot_disk {
      initialize_params {
          image_id = data.yandex_compute_image.nat_instance_ubuntu_image.id
          size = 10
      }
  }

  network_interface {
      subnet_id = yandex_vpc_subnet.nat_instance_public_subnet.id
      nat       = true
  }

  metadata = {
      user-data = <<-EOT
        #cloud-config
        ssh_pwauth: no
        users:
          - name: ${var.default_user}
            sudo: ALL=(ALL) NOPASSWD:ALL
            shell: /bin/bash
            ssh_authorized_keys:
              - ${file("~/.ssh/${var.private_key_file}.pub")}
        EOT
  }


}

