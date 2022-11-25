resource "yandex_compute_instance" "proxy_docker_instance" {
  name = "proxy-docker-instance"
  zone = "${yandex_vpc_subnet.web_front_subnets.0.zone}"


  labels = { 
    ansible_group = "proxy_docker_instance"
  }

  resources {
      cores  = 2
      core_fraction = 20
      memory = 1
  }

  scheduling_policy {
      preemptible  = true
  }

  boot_disk {
      initialize_params {
          image_id = data.yandex_compute_image.container_optimized_image.id
          size = 30
      }
  }


  network_interface {
      subnet_id       = yandex_vpc_subnet.web_front_subnets.0.id
      ip_address = "10.129.0.102"
      nat = true
  }  

  metadata = {
    # docker-compose = file("${path.module}/docker-compose-pg.yaml")
    docker-compose = <<-EOT
        version: "3"

        services:
            proxy:
                image: nginx
                container_name: web-proxy
                restart: always
                ports:
                - 80:80
                - 443:443
                volumes:
                - /home/${var.default_user}/certs:/etc/nginx/certs:ro
                - /home/${var.default_user}/nginx/nginx.conf:/etc/nginx/conf.d/default.conf 
        EOT
    ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
  }
}

## Copy ssl certificates and nginx configuration to proxy
resource "null_resource" "copy_nginx_files" {
  depends_on = [yandex_compute_instance.proxy_docker_instance]
# Connection Block for Provisioners to connect to VM Instance
  connection {
    type = "ssh"
    host = yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address
    user = var.default_user
    private_key = file("~/.ssh/${var.private_key_file}")
  }

## Remote Exec Provisioner: creates a directory with nginx certificates and configuration - to further use by nginx instance
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/${var.default_user}/nginx",
      "mkdir /home/${var.default_user}/certs"
    ]
  } 
## File Provisioner: Copies nginx configuration to proxy server
  provisioner "file" {
    source      = "${path.module}/nginx/"
    destination = "/home/${var.default_user}/nginx"
  }
## File Provisioner: Copies ssl certificates to proxy server
  provisioner "file" {
    source      = "${path.module}/certs/"
    destination = "/home/${var.default_user}/certs"
  }  
}