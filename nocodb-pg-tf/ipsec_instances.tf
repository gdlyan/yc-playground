data "yandex_compute_image" "ipsec_instance_image" {
  family = "ipsec-instance-ubuntu"
}

resource "yandex_compute_instance" "ipsec_instances" {
  count = length(var.ipsec_instances)
  name = "ipsec-instance-${count.index}"
  zone = "${yandex_vpc_subnet.web_front_subnets[var.ipsec_instances[count.index].subnet_ix].zone}"


  labels = { 
    ansible_group = "ipsec_instance"
  }

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
          image_id = data.yandex_compute_image.ipsec_instance_image.id
          size = 30
      }
  }

  network_interface {
      subnet_id = yandex_vpc_subnet.web_front_subnets[var.ipsec_instances[count.index].subnet_ix].id
      nat       = true 
      security_group_ids = [yandex_vpc_security_group.vpn_sg.id]
  }  
}