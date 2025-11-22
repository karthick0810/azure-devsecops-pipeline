terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# ---------- PROVIDER CONFIG ----------
provider "azurerm" {
  features {}

  # From: az account list --output table
  subscription_id = "8289f74c-b40d-449a-bb8a-e0712c80e858"
  tenant_id       = "262d120a-209a-4d88-a10a-1c718bac81d3"
}

# ---------- EXISTING RESOURCE GROUP ----------
# Your VM is in this resource group: Existing-resources
resource "azurerm_resource_group" "existing_rg" {
  name     = "Existing-resources"
  location = "centralindia" # region short name
}

# ---------- EXISTING VM (IMPORTED) ----------
resource "azurerm_linux_virtual_machine" "testing_vm" {
  # From the portal / state
  name                = "testing"
  resource_group_name = azurerm_resource_group.existing_rg.name
  location            = azurerm_resource_group.existing_rg.location
  size                = "Standard_B1s"

  # Existing NIC ID from Azure
  network_interface_ids = [
    "/subscriptions/8289f74c-b40d-449a-bb8a-e0712c80e858/resourceGroups/Existing-resources/providers/Microsoft.Network/networkInterfaces/testing519_z1"
  ]

  # Match what Terraform saw in the plan:
  # admin_username = "karthick"
  admin_username                  = "karthick"
  disable_password_authentication = false

  # You MUST set a password in config when password auth is enabled.
  # This will update the VM password if you run `terraform apply`.
  admin_password = "ChangeMe!123!" # <-- put a strong password here, don't commit this

  # These were shown in the plan as enabled and forcing replacement if removed
  zone                  = "1"
  secure_boot_enabled   = true
  vtpm_enabled          = true
  encryption_at_host_enabled = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS" # match current disk type to avoid replacement
  }

  # Match the image that the plan showed on the LEFT side
  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
