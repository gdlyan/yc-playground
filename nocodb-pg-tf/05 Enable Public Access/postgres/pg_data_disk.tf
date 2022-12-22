data "yandex_compute_snapshot" "pg_data_disk_snapshot" {
  count          = (var.recreate_data_disk == "none" || var.recreate_data_disk == "empty") ? 0 : 1
  name           = var.recreate_data_disk
}

resource "yandex_compute_disk" "pg_data_disk" {
  count       = var.recreate_data_disk == "none" ? 0 : 1
  name        = "pg-data-disk"
  snapshot_id = (var.recreate_data_disk == "none" || var.recreate_data_disk == "empty") ? null : data.yandex_compute_snapshot.pg_data_disk_snapshot.0.id
  type        = "network-hdd"
  zone        = var.subnet.zone
  size        = var.pg_data_disk_size
}

data "yandex_compute_disk" "pg_data_disk" {
  count = var.recreate_data_disk == "none" ? 1 : 0
  name  = "pg-data-disk"
}