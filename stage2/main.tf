variable "django_secret_key_prod" {
  description = "Production Django secret key passed to container runtime."
  type        = string
  sensitive   = true
}

variable "arm_client_id" {
  description = "Service principal client id used for ACR pull auth."
  type        = string
  sensitive   = true
}

variable "arm_client_secret" {
  description = "Service principal client secret used for ACR pull auth."
  type        = string
  sensitive   = true
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.68.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-acmp-final"
    storage_account_name = "acmp2400storageaccount"
    container_name       = "big-tf-state-acmp2400"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_container_registry" "dswanberg-acr" {
  name                = "acrdswanbergacmp2400"
  resource_group_name = "rg-dswanberg"
  location            = "Central US"
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_container_group" "dswanberg-instance" {
  name                = "acmp-dswanberg-instance"
  location            = "Central US"
  resource_group_name = "rg-dswanberg"
  ip_address_type     = "Public"
  os_type             = "Linux"
  dns_name_label      = "acmpdswanberginstance"

  container {
    name   = "final"
    image  = "acrdswanbergacmp2400.azurecr.io/final:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 8000
      protocol = "TCP"
    }

    secure_environment_variables = {
      DJANGO_SECRET_KEY = var.django_secret_key_prod
    }
  }

  image_registry_credential {
    server   = "acrdswanbergacmp2400.azurecr.io"
    username = var.arm_client_id
    password = var.arm_client_secret
  }
}
