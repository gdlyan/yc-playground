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
      # nat = true
  }  

  metadata = {
    # docker-compose = file("${path.module}/docker-compose-app.yaml")
    docker-compose = <<-EOT
      version: '3'
      services:
        nocodb_app: 
          container_name: nocodb_app
          environment: 
            NC_AUTH_JWT_SECRET: "569a1821-0a93-45e8-87ab-eb857f20a010"
            NC_DB: "pg://${yandex_compute_instance.pg_docker_instances.0.network_interface.0.ip_address}:5432?u=${var.default_user}&p=${var.postgres_password}&d=${var.nocodb_database}" 
          image: "nocodb/nocodb:latest"
          ports:
            - 80:8080
          restart: unless-stopped
          volumes: 
            - "./nocodb/data:/usr/app/data"    
      EOT
    ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
  }
}