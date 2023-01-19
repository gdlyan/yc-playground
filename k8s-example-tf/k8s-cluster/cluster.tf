resource "yandex_kubernetes_cluster" "k8s_cluster" {
 network_id = var.network_id 
 master {
   zonal {
     zone      = var.subnet.zone
     subnet_id = var.subnet.id
   }
   public_ip = true
 }
 service_account_id      = yandex_iam_service_account.k8s_resources_sa.id
 node_service_account_id = yandex_iam_service_account.k8s_nodes_sa.id
   depends_on = [
     yandex_resourcemanager_folder_iam_binding.editor_account_iam,
     yandex_resourcemanager_folder_iam_binding.image_puller_account_iam
   ]
}


resource "yandex_kubernetes_node_group" "node-group-nano-autoscale-1-5" {
  cluster_id  = yandex_kubernetes_cluster.k8s_cluster.id
  name        = "node-group-nano-autoscale-1-5"
  version     = yandex_kubernetes_cluster.k8s_cluster.master[0].version

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = true
      subnet_ids         = ["${var.subnet.id}"]
    }

    resources {
      memory = 1
      cores  = 2
      core_fraction = 20
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = true
    }

    container_runtime {
      type = "docker"
    }

    metadata = {
      ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
    }
  }

  scale_policy {
    auto_scale {
      min = 1
      max = 5
      initial = 1
    }
  }

  allocation_policy {
    location {
      zone = var.subnet.zone
    }
  }
}