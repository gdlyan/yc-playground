resource "yandex_compute_disk" "pg_data_disk" {
  count    = length(var.pg_docker_instances)
  name     = "pg-data-disk-${count.index}"

  type     = "network-hdd"
  size     = var.pg_data_disk_size
  zone     = "${yandex_vpc_subnet.webapp_subnets[var.pg_docker_instances[count.index].subnet_ix].zone}"
}