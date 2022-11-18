terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    } 
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
    null = {
      source = "hashicorp/null"
      version = ">= 3.0"
    }   
  }
  required_version = ">= 0.13"
}