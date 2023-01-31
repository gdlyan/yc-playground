output "conn_string" {
    value = "pg://c-${yandex_mdb_postgresql_cluster.pg_nano.id}.rw.mdb.yandexcloud.net:6432?d=${yandex_mdb_postgresql_database.database.name}&u=${yandex_mdb_postgresql_user.uid.name}&p=${local.sqlpassword}"
}