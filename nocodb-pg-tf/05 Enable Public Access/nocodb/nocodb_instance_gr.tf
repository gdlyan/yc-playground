data "template_file" "docker_compose_yaml" {
  template = file("${path.module}/docker-compose.tpl.yaml")
  vars = {
    DEFAULT_USER             = var.default_user
    POSTGRES_USER            = var.default_user
    POSTGRES_PASSWORD        = var.postgres_password
    PG_INSTANCE_PRIVATE_IP   = var.pg_instance_private_ip
    NOCODB_DATABASE          = var.nocodb_database
  }
}

data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance_group" "nocodb_instances" {
  
  service_account_id = yandex_iam_service_account.nocodb_manager_sa.id
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.editor_account_iam 
  ]

  instance_template {

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
      subnet_ids = var.subnet_ids 
    }  

    labels = {
      postgres = var.pg_instance_private_ip
    }

    metadata = {
        docker-compose = data.template_file.docker_compose_yaml.rendered
        ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = var.zones
  }

  deploy_policy {
    max_unavailable = 2
    max_expansion   = 2
  }
}

