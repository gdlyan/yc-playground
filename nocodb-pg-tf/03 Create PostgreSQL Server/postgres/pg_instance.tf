data "template_file" "docker_compose_pg_yaml" {
  template = file("${path.module}/docker-compose-pg.tpl.yaml")
  vars = {
    DEFAULT_USER             = var.default_user
    POSTGRES_USER            = var.default_user
    POSTGRES_PASSWORD        = var.postgres_password
    PGADMIN_DEFAULT_EMAIL    = var.pgadmin_credentials.email
    PGADMIN_DEFAULT_PASSWORD = var.pgadmin_credentials.password
  }
}

data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "pg_docker_instance" {
  name = "pg-docker-instance"
  zone = var.subnet.zone

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

  secondary_disk {
    disk_id = var.recreate_data_disk == "none" ? data.yandex_compute_disk.pg_data_disk.0.id : yandex_compute_disk.pg_data_disk.0.id
    device_name = "pgdata"
  }

  network_interface {
      subnet_id       = var.subnet.id
      ip_address      = var.pg_private_ip_address
  }  

  metadata = {
    docker-compose = data.template_file.docker_compose_pg_yaml.rendered
    ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
  }
}