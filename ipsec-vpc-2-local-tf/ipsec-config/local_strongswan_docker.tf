# Runs the strongswan locally in docker
# Similar to the following `docker run` instruction
# docker run -itd --name strongswan \
#   --cap-add NET_ADMIN \
#   --net=host \
#   -v $(pwd)/ipsec-config/local/ipsec.secrets:/etc/ipsec.secrets \
#   -v $(pwd)/ipsec-config/local/ipsec.conf:/etc/ipsec.conf \
#   mberner/strongswan:5.9.7 
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "strongswan" {
  name = "mberner/strongswan:5.9.7"
}

resource "docker_volume" "ipsec_conf" {

}

resource "docker_container" "strongswan" {
  depends_on = [
    local_file.local_ipsec_conf,
    local_file.local_ipsec_secrets,
    null_resource.cp_ipsec_config_to_cloud
  ]
  image = docker_image.strongswan.image_id
  name  = "strongswan"
  network_mode = "host"
  capabilities {
    add = ["NET_ADMIN"]
  }
/*   volumes {
    container_path = "/etc/ipsec.d/conf"
    host_path      = "${var.ipsec_conf_local_dir}"
  } */
  volumes {
    container_path = "/etc/ipsec.conf"
    host_path      = "${var.ipsec_conf_local_dir}/ipsec.conf"
  }
  volumes {
    container_path = "/etc/ipsec.secrets"
    host_path      = "${var.ipsec_conf_local_dir}/ipsec.secrets"
  } 
}

/* resource "null_resource" "waiter" {
  depends_on = [
    docker_container.strongswan
  ]
  provisioner "local-exec" {
    command = "sleep 240"
  }
} */


