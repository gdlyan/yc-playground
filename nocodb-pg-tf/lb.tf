resource "yandex_lb_network_load_balancer" "nlb" {
  name = "load-balancer"

  listener {
    name = "listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
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

  target {
    subnet_id = "${yandex_vpc_subnet.webapp_subnets.0.id}"
    address   = "${yandex_compute_instance.webapp_instances.0.network_interface.0.ip_address}"
  }

}