resource "yandex_lb_network_load_balancer" "nlb" {
  name = "load-balancer"
  type = "internal"

  listener {
    name = "nocodb-upstream-listener"
    port = 80
    target_port = 80
    internal_address_spec {
      subnet_id  = var.nlb_subnet.id
      address    = cidrhost(var.nlb_subnet.v4_cidr_blocks[0], 101) 
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.tg.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/dashboard/"
      }
    }
  }
}

resource "yandex_lb_target_group" "tg" {
  name      = "web-service-tg"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance_group.nocodb_instances.instances
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }

  }

}