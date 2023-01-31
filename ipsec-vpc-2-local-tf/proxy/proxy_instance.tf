## Generate nginx.conf
data "template_file" "nginx_conf" {
  template = file("${path.module}/nginx.tpl.conf")
  vars = {
    DOMAIN                   = var.domain
    SUBDOMAIN                = var.subdomain
    NLB_INSTANCE_PRIVATE_IP  = var.nlb_instance_private_ip
  }
}

resource "local_file" "nginx_conf" {
  content = data.template_file.nginx_conf.rendered
  filename = "${path.module}/nginx/nginx.conf"
}

# Create virtual machine
data "template_file" "docker_compose_yaml" {
  template = file("${path.module}/docker-compose.tpl.yaml")
  vars = {
    DEFAULT_USER             = var.default_user
  }
}

data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "proxy_docker_instance" {
  name = "proxy-docker-instance"
  zone = "${var.proxy_subnet.zone}"


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
      subnet_id       = var.proxy_subnet.id
      ip_address      = cidrhost(var.proxy_subnet.v4_cidr_blocks[0], 102)
      nat = true
      security_group_ids = [var.sg_proxy_id]
  }  

  metadata = {
    docker-compose = data.template_file.docker_compose_yaml.rendered
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
    source      = "${path.module}/certs/archive/${var.domain}/"
    destination = "/home/${var.default_user}/certs"
  }  
}