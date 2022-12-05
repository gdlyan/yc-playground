data "template_file" "cloud_config_yaml" {
  template = file("${path.module}/cloud-config.tpl.yaml")
  vars = {
    DEFAULT_USER            = var.default_user
    PRIVATE_KEY_FILE        = var.private_key_file
  }
}