resource "null_resource" "vm_ids_file" {
  for_each = var.vm_map
  connection {
    type     = "ssh"
    user     = "root"
    password = each.value.pve_node_pass
    host     = each.value.node_ip

  }

  provisioner "file" {
    source      = "./files/vms-ids.sh"
    destination = "/tmp/vms-ips-${each.value.vm_name}.sh"
  }

}

resource "null_resource" "vm_id_data" {
  depends_on = [null_resource.vm_ids_file]
  for_each   = var.vm_map

  connection {
    type     = "ssh"
    user     = "root"
    password = each.value.pve_node_pass
    host     = each.value.node_ip
  }

  provisioner "remote-exec" {
    inline = [

      "chmod u+x /tmp/vms-ips-${each.value.vm_name}.sh",
      "/tmp/vms-ips-${each.value.vm_name}.sh \"/tmp/vms-ips-${each.value.vm_name}.txt\""
    ]
  }


}
data "remote_file" "vm_array" {
  depends_on = [null_resource.vm_id_data]
  for_each   = var.vm_map
  conn {

    host     = each.value.node_ip
    password = each.value.pve_node_pass
    user     = "root"
  }
  path = "/tmp/vms-ips-${each.value.vm_name}.txt"
}



