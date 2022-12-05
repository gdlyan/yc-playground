variable "token" {
  description = "echo $TF_VAR_token (env varriable should be exported in advance) or set in terraform.tfvars"
  type        = string
}

variable "cloud_id" {
  description = "Yandex cloud id from yc config list"
  type        = string
}

variable "folder_id" {
  description = "Yandex folder id from yc config list"
  type        = string
}
