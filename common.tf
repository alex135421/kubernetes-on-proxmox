

resource "null_resource" "cloud_user_config_files" {
  for_each = var.vm_map
  connection {
    type     = "ssh"
    user     = "root"
    password = each.value.pve_node_pass
    host     = each.value.node_ip

  }

  provisioner "file" {
    content = templatefile("./templates/kub-${each.value.kub_type}.tftpl", { ip = each.value.ip_addr,
      pub_ssh              = each.value.public_key,
      host_name            = each.value.vm_name,
      worker_to_master_pub = var.worker_to_master_public_key,
      user                 = each.value.vm_user,
      master_ip            = each.value.master_id != "" ? var.vm_map[each.value.master_id].ip_addr : "",
      master_user          = each.value.master_id != "" ? var.vm_map[each.value.master_id].vm_user : ""
    sleep_time = each.value.sleep_time })

    destination = "/var/lib/vz/snippets/user_data_vm-${each.value.vm_name}.yml"
  }

}
resource "null_resource" "cloud_net_config_files" {
  for_each = var.vm_map
  connection {
    type     = "ssh"
    user     = "root"
    password = each.value.pve_node_pass
    host     = each.value.node_ip

  }

  provisioner "file" {

    content     = templatefile("./templates/kub-network.tftpl", { ip = each.value.ip_addr })
    destination = "/var/lib/vz/snippets/network_data_vm-${each.value.vm_name}.yml"
  }

}

