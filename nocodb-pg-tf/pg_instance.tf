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

  network_interface {
      subnet_id       = yandex_vpc_subnet.webapp_subnets[var.pg_docker_instances[count.index].subnet_ix].id
      ip_address      = "10.130.0.101"
      # nat = true
  }  

  metadata = {
    # docker-compose = file("${path.module}/docker-compose-pg.yaml")
    docker-compose = <<-EOT
        version: "3"

        services:
            postgres:
                image: postgres:12.3-alpine
                restart: always
                environment:
                    POSTGRES_PASSWORD: ${var.postgres_password}
                    POSTGRES_USER: ${var.default_user}
                ports:
                    - 5432:5432
                volumes:
                    - pgdata:/var/lib/postgresql/data

            pgadmin:
                image: dpage/pgadmin4:4.23
                environment:
                    PGADMIN_DEFAULT_EMAIL: ${var.pgadmin_credentials.email}
                    PGADMIN_DEFAULT_PASSWORD: ${var.pgadmin_credentials.password}
                    PGADMIN_LISTEN_PORT: 80
                ports:
                    - 80:80
                volumes:
                    - pgadmin:/var/lib/pgadmin
                depends_on:
                    - postgres

        volumes:
            pgdata: {}
            pgadmin: {}    
        EOT
    ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
  }
}