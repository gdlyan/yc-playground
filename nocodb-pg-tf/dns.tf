resource "yandex_dns_zone" "gdlyan_com_public_zone" {
  name        = "gdlyan-com-public-zone"
  description = "Public zone"
  zone        = "${var.domain}."
  public      = true
}

resource "yandex_dns_recordset" "a_record_nocodb" {
  zone_id = yandex_dns_zone.gdlyan_com_public_zone.id
  name    = "nocodb.${var.domain}."
  ttl     = 600
  type    = "A"
  data    = [yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "a_record_pgadmin" {
  zone_id = yandex_dns_zone.gdlyan_com_public_zone.id
  name    = "pgadmin.${var.domain}."
  ttl     = 600
  type    = "A"
  data    = [yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address]
}



