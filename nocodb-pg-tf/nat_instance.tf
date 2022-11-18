data "yandex_compute_image" "nat_instance_ubuntu_image" {
  family = "nat-instance-ubuntu"
}

resource "yandex_compute_instance" "nat_instance_tf" {
  name = "nat-instance-tf"
  zone = yandex_vpc_subnet.web_front_subnets.0.zone

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
      subnet_id = yandex_vpc_subnet.web_front_subnets.0.id
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

## Copy ssh-keys to use this NAT instance as ssh bastion
resource "null_resource" "copy_ssh_key" {
  depends_on = [yandex_compute_instance.nat_instance_tf]
# Connection Block for Provisioners to connect to Azure VM Instance
  connection {
    type = "ssh"
    host = yandex_compute_instance.nat_instance_tf.network_interface.0.nat_ip_address
    user = var.default_user
    private_key = file("~/.ssh/${var.private_key_file}")
  }

## File Provisioner: Copies the private key file to NAT instance
  provisioner "file" {
    source      = "~/.ssh/${var.private_key_file}"
    destination = "/home/${var.default_user}/.ssh/${var.private_key_file}"
  }
## Remote Exec Provisioner: fix the private key permissions on NAT instance
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /home/${var.default_user}/.ssh/${var.private_key_file}"
    ]
  }
}

