terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }  
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }            
  }
  required_version = ">= 0.13"
}
