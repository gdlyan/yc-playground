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
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }  
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }   
  }
  required_version = ">= 0.13"
}