
resource "proxmox_vm_qemu" "kubernetes" {
  for_each = { for key, val in var.vm_map : key => val }
  depends_on = [
    null_resource.cloud_user_config_files,
    null_resource.cloud_net_config_files,
    data.remote_file.vm_array,
  ]

  vmid = jsondecode(data.remote_file.vm_array[each.key].content)["vms"][index(values(var.vm_map), each.value)]

  name = each.value.vm_name
  desc = "${each.value.vm_name} is a ${each.value.kub_type}"

  target_node = each.value.pve_node

  # The template name to clone this vm from
  clone = each.value.cloud_init_tpl
  vga {
    type = "std"
  }

  # Activate QEMU agent for this VM
  agent = 1

  os_type = "cloud-init"
  cores   = each.value.vm_cores
  sockets = each.value.vm_sockets
  vcpus   = 0
  cpu     = "host"
  memory  = each.value.vm_memory
  scsihw  = "virtio-scsi-pci"

  ciupgrade = true
  cicustom  = "user=local:snippets/user_data_vm-${each.value.vm_name}.yml,network=local:snippets/network_data_vm-${each.value.vm_name}.yml"
  disks {
    ide {
      ide3 {
        cloudinit {
          storage = each.value.vm_ci_storage
        }
      }
    }
    scsi {

      scsi0 {
        disk {
          size     = each.value.vm_disk_size
          cache    = "writeback"
          storage  = each.value.vm_storage
          iothread = false
          discard  = true
        }
      }

    }
  }

  network {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = true
  }

  boot = "order=scsi0"

  #cloud init state always changes and destroys vm
  lifecycle {
    ignore_changes = [
      disks[0].ide[0].ide3[0].cloudinit,
      ciupgrade,
      cicustom,
      clone,
      vmid
    ]
  }
}
resource "time_sleep" "wait_in_seconds" {
  depends_on = [proxmox_vm_qemu.kubernetes]

  create_duration = var.wait_for_workers
}
resource "null_resource" "pass_data_to_worker" {

  depends_on = [time_sleep.wait_in_seconds]
  for_each   = { for key, val in var.vm_map : key => val if val.kub_type == "worker" }
  provisioner "file" {
    content     = var.worker_to_master_private_key
    destination = "/home/${each.value.vm_user}/.ssh/master_private"
    connection {
      type = "ssh"
      user = each.value.vm_user
      host = each.value.ip_addr
    }
  }
}

