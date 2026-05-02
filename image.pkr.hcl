packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 1.0.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.0.0"
    }
  }
}


# -----------------------------
# Variables (from GitHub Secrets)
# -----------------------------
variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

#  IMPORTANT: must exist (fix for your error)
variable "image_version" {
  type = string
}

# -----------------------------
# Azure Image Source
# -----------------------------
source "azure-arm" "ubuntu" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  # Keep region consistent with your SIG
  location = "switzerlandnorth"
  vm_size  = "Standard_B2ls_v2"

 # os_type         = "Linux"
 # image_publisher = "canonical"
 # image_offer     = "0001-com-ubuntu-server-jammy"
 # image_sku       = "22_04-lts"


  os_type         = "Linux"
  image_publisher = "canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"  

# (24.04 sometimes fails in some regions → 22.04 is stable)

  # Temporary managed image
  managed_image_resource_group_name = "vaithee-packer-rg"
  managed_image_name                = "temp-image-${var.image_version}"

  # Shared Image Gallery (SIG)
  shared_image_gallery_destination {
    subscription   = var.subscription_id
    resource_group = "vaithee-rg"
    gallery_name   = "vaithee_gallery"
    image_name     = "vaithee-ubuntu-image"
    image_version  = var.image_version

    replication_regions = ["Central India"]
  }

  # Optional but recommended
  azure_tags = {
    environment = "dev"
    created_by  = "packer"
  }
}

# -----------------------------
# Build Block
# -----------------------------
build {
  name    = "azure-ubuntu-image"
  sources = ["source.azure-arm.ubuntu"]

  # Required for Ansible
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3"
    ]
  }

  # Run your Ansible playbook
  provisioner "ansible" {
    playbook_file = "./ansible/playbook.yml"
  }
}
