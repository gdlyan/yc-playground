##Cloud side
data "template_file" "cloud_ipsec_conf" {
  template = file("${path.module}/cloud.tpl.ipsec.conf")
  vars = {
    IPSEC_INSTANCE_PUBLIC_IP = var.ipsec_instance_public_ip
    CLOUD_SUBNET             = var.cloud_subnet
    LOCAL_PUBLIC_IP          = var.local_public_ip
    LOCAL_SUBNET             = var.local_subnet
  }
}

data "template_file" "cloud_ipsec_secrets" {
  template = file("${path.module}/cloud.tpl.ipsec.secrets")
  vars = {
    IPSEC_INSTANCE_PUBLIC_IP = var.ipsec_instance_public_ip
    LOCAL_PUBLIC_IP          = var.local_public_ip
    PSK                      = var.psk
  }
}

resource "local_file" "cloud_ipsec_conf" {
  content = data.template_file.cloud_ipsec_conf.rendered
  filename = "${path.module}/cloud/ipsec.conf"
}

resource "local_file" "cloud_ipsec_secrets" {
  content = data.template_file.cloud_ipsec_secrets.rendered
  filename = "${path.module}/cloud/ipsec.secrets"
}



##Local side
data "template_file" "local_ipsec_conf" {
  template = file("${path.module}/local.tpl.ipsec.conf")
  vars = {
    IPSEC_INSTANCE_PUBLIC_IP = var.ipsec_instance_public_ip
    CLOUD_SUBNET             = var.cloud_subnet
    LOCAL_PUBLIC_IP          = var.local_public_ip
    LOCAL_SUBNET             = var.local_subnet
  }
}

data "template_file" "local_ipsec_secrets" {
  template = file("${path.module}/local.tpl.ipsec.secrets")
  vars = {
    IPSEC_INSTANCE_PUBLIC_IP = var.ipsec_instance_public_ip
    LOCAL_PUBLIC_IP          = var.local_public_ip
    PSK                      = var.psk
  }
}

resource "local_file" "local_ipsec_conf" {
  content = data.template_file.local_ipsec_conf.rendered
  filename = "${path.module}/local/ipsec.conf"
}

resource "local_file" "local_ipsec_secrets" {
  content = data.template_file.local_ipsec_secrets.rendered
  filename = "${path.module}/local/ipsec.secrets"
}