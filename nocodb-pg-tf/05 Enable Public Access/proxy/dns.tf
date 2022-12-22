data "yandex_dns_zone" "public_zone" {
  name        = "${replace(var.domain, ".", "-")}-public-zone"
}

resource "yandex_dns_recordset" "a_record_nocodb" {
  zone_id = data.yandex_dns_zone.public_zone.id
  name    = "${var.subdomain}.${var.domain}."
  ttl     = 600
  type    = "A"
  data    = [yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "a_record_pgadmin" {
  zone_id = data.yandex_dns_zone.public_zone.id
  name    = "pgadmin.${var.domain}."
  ttl     = 600
  type    = "A"
  data    = [yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address]
}