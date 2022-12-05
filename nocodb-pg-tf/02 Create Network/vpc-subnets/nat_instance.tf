# Create NAT instance
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
      subnet_id  = yandex_vpc_subnet.web_front_subnets.0.id
      ip_address = var.nat_ip_address
      nat        = true
  }

  metadata = {
      user-data = data.template_file.cloud_config_yaml.rendered
  }
}