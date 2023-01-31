resource "yandex_mdb_postgresql_cluster" "pg_nano" {
  name        = "nocodb_postgresql"
  environment = "PRESTABLE"
  network_id  = var.network_id
  security_group_ids = [var.sg_mdb_id]
  config {
    version = 12  
    resources {
      resource_preset_id = "b2.nano"
      disk_type_id       = "network-hdd"
      disk_size          = 10
    }
    access {
      web_sql            = true
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 12
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = var.subnets[0].id
  }

/*   host {
    zone      = "ru-central1-b"
    subnet_id = var.subnets[1].id
  }

  host {
    zone      = "ru-central1-c"
    subnet_id = var.subnets[2].id
  } */
}

resource "yandex_mdb_postgresql_database" "database" {
  cluster_id = yandex_mdb_postgresql_cluster.pg_nano.id
  name       = var.dbname
  owner      = yandex_mdb_postgresql_user.uid.name
}

resource "yandex_mdb_postgresql_user" "uid" {
    cluster_id = yandex_mdb_postgresql_cluster.pg_nano.id
    name       = var.dbuser
    password   = local.sqlpassword
}