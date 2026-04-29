terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.68.0"
    }
  }

  # Stage 3 uses the same remote backend as stage 1/2, but intentionally defines
  # no resources so Terraform will destroy everything managed in the state.
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

