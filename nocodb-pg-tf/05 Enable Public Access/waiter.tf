## When Postgres is up it does not necessarily mean that it is ready to serve queries, 
## it might need some more time
## Sometimes NocoDB instances start querying postgres before it is ready to serve queries
## In such a situation NocoDB container fails to listen on port 80 until the VM restarted
## This code is aimed at giving some time to Postgres to warm up and become ready to serve queries from NocoDB in order to prevent this kind of failures 
resource "null_resource" "postgres_warmup" {
  depends_on = [
    module.postgres.pg_instance_private_ip
  ]
  provisioner "local-exec" {
    command = "sleep 60"
  }
}