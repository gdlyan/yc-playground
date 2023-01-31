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
    target_group_id = yandex_compute_instance_group.nocodb_instances.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/api/v1/health"
      }
    }
  }
}
