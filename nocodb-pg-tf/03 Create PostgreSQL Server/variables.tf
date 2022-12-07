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

variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

variable "postgres_password" {
  description = "Postgres password for default_user"
  type        = string  
}

variable "pgadmin_credentials" {
  type        =  object({email = string, password = string})  
}

variable "recreate_data_disk" {
 description = "none - use existing disk; empty - create new empty disk; snapshot - create from snapshot with the name == variable value"
 type        = string
 default     = "none"
}

