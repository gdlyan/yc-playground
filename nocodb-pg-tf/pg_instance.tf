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

resource "yandex_compute_instance" "pg_docker_instances" {
  count = length(var.pg_docker_instances)
  name = "pg-docker-instance-${count.index}"
  zone = "${yandex_vpc_subnet.webapp_subnets[var.pg_docker_instances[count.index].subnet_ix].zone}"


  labels = { 
    ansible_group = "pg_docker_instance"
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

  secondary_disk {
    disk_id = "${yandex_compute_disk.pg_data_disk[count.index].id}"
    device_name = "pgdata"
  }

  network_interface {
      subnet_id       = yandex_vpc_subnet.webapp_subnets[var.pg_docker_instances[count.index].subnet_ix].id
      ip_address      = "10.130.0.101"
      # nat = true
  }  

  metadata = {
    docker-compose = data.template_file.docker_compose_pg_yaml.rendered
    ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
  }
}