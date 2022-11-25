resource "yandex_lb_network_load_balancer" "nlb" {
  name = "load-balancer"
  type = "internal"

  listener {
    name = "nocodb-upstream-listener"
    port = 80
    target_port = 80
    internal_address_spec {
      subnet_id  = yandex_vpc_subnet.web_front_subnets.0.id
      address    = "10.129.0.101"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.tg.id}"

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 80
      }
    }
  }
}

resource "yandex_lb_target_group" "tg" {
  name      = "web-service-tg"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance.webapp_instances
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }

  }

}
