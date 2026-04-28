terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

variable "state_key" {
  description = "Unique key used for state isolation and naming."
  type        = string
}

locals {
  resource_group_name = "rg${var.state_key}"
  acr_name            = "${var.state_key}acr"
}

data "azurerm_resource_group" "target" {
  name = local.resource_group_name
}

resource "azurerm_container_registry" "app" {
  name                = local.acr_name
  resource_group_name = data.azurerm_resource_group.target.name
  location            = data.azurerm_resource_group.target.location
  sku                 = "Basic"
  admin_enabled       = false
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry."
  value       = azurerm_container_registry.app.login_server
}
