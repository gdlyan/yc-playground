data "yandex_compute_snapshot" "pg_data_disk_snapshot" {
  name           = "pg-data-disk-snapshot"
}

resource "yandex_compute_disk" "pg_data_disk" {
  count    = length(var.pg_docker_instances)
  name     = "pg-data-disk-${count.index}"
  # snapshot_id = data.yandex_compute_snapshot.pg_data_disk_snapshot.id
  type     = "network-hdd"
  zone     = "${yandex_vpc_subnet.webapp_subnets[var.pg_docker_instances[count.index].subnet_ix].zone}"
  size     = var.pg_data_disk_size
}