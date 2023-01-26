# Copies ./cloud/ipsec.conf an ./cloud/ipsec.secrets to the ipsec instance
# Then runs `sudo service ipsec restart` to apply the updated config

resource "null_resource" "cp_ipsec_config_to_cloud" {
    depends_on = [
        local_file.cloud_ipsec_conf,
        local_file.cloud_ipsec_secrets
    ]
# Connection Block for Provisioners to connect to VM Instance
  connection {
    type = "ssh"
    host = var.ipsec_instance_public_ip
    user = var.default_user
    private_key = file("~/.ssh/${var.private_key_file}")
  }

## Remote Exec Provisioner: creates a directory with nginx certificates and configuration - to further use by nginx instance
  provisioner "remote-exec" {
    inline = [
        "mkdir /home/${var.default_user}/ipsec_conf"
    ]
  } 

## File Provisioner: Copies nginx configuration to proxy server
  provisioner "file" {
    source      = "${path.module}/cloud/"
    destination = "/home/${var.default_user}/ipsec_conf"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo cp /home/${var.default_user}/ipsec_conf/* /etc",
        "sudo service ipsec restart",
        "rm -rf /home/${var.default_user}/ipsec_conf"
    ]
  }
}

