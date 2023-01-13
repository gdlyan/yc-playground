 source "yandex" "ubuntu-1804-nginx" {
   token               = "${var.token}"
   folder_id           = "${var.folder_id}"
   source_image_family = "ubuntu-1804-lts"
   ssh_username        = "ubuntu"
   use_ipv4_nat        = "true"
   image_description   = "my custom ubuntu 1804 with nginx"
   image_family        = "ubuntu-1804-lts"
   image_name          = "ubuntu-1804-nginx"
   subnet_id           = "${var.subnet_id}"
   disk_type           = "network-ssd"
   zone                = "${var.zone_id}"
 }

  source "yandex" "ubuntu-2004-nginx" {
   token               = "${var.token}"
   folder_id           = "${var.folder_id}"
   source_image_family = "ubuntu-2004-lts"
   ssh_username        = "ubuntu"
   use_ipv4_nat        = "true"
   image_description   = "my custom ubuntu 2004 with nginx"
   image_family        = "ubuntu-2004-lts"
   image_name          = "ubuntu-2004-nginx"
   subnet_id           = "${var.subnet_id}"
   disk_type           = "network-ssd"
   zone                = "${var.zone_id}"
 }

 build {
   sources = ["source.yandex.ubuntu-1804-nginx",
              "source.yandex.ubuntu-2004-nginx"]

   provisioner "shell" {
     inline = [
              # Wait for cloud-init finish 
              "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
              # Wait unattended upgrade to release /var/lib/dpkg/lock-frontend
              "while pgrep apt; do echo 'Waiting for unattended upgrade...'; sleep 1; done;",
              # Basic Ubuntu things
              "sudo apt-get update -y",
              "echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections",
              # NGINX on the virtual machine, port 80
              "sudo apt-get install -y nginx",
              "sudo systemctl enable nginx.service",
              # Docker
              "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-keyring.gpg",
              "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
              "sudo apt-get update",
              "sudo apt-get install -y docker-ce containerd.io docker-compose",
              "sudo usermod -aG docker $USER",
              "sudo chmod 666 /var/run/docker.sock",
              # Run containerized app
              "docker run --init --restart always -d -p 3000:3000 -v $(pwd):/home/workspace:cached gitpod/openvscode-server"              
              ]
   }
 }