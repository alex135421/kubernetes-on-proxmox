terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc4"

    }

    remote = {
      source  = "tenstad/remote"
      version = "0.1.3"
    }
  }
  required_version = ">= 1.0"
}
provider "proxmox" {
  pm_api_url = "https://192.168.0.200:8006/api2/json"
}
