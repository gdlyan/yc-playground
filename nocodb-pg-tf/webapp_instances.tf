data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}


 

resource "yandex_compute_instance" "webapp_instances" {
  count = length(var.webapp_instances)
  name = "webapp-instance-${count.index}"
  zone = "${yandex_vpc_subnet.webapp_subnets[var.webapp_instances[count.index].subnet_ix].zone}"


  labels = { 
    ansible_group = "webapp_instance"
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
          image_id = data.yandex_compute_image.container_optimized_image.id
          size = 30
      }
  }

  network_interface {
      subnet_id       = yandex_vpc_subnet.webapp_subnets[var.webapp_instances[count.index].subnet_ix].id
      security_group_ids = [yandex_vpc_security_group.web_service_sg.id]
  }  
}