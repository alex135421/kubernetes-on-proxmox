variable "vm_map" {
  type = map(object({
    vm_name        = string
    vm_user        = string
    vm_storage     = string
    vm_disk_size   = string
    vm_sockets     = string
    vm_cores       = string
    vm_memory      = string
    vm_ci_storage  = string
    node_ip        = string
    kub_type       = string
    pve_node       = string
    pve_node_pass  = string
    ci_iso_storage = string
    ip_addr        = string
    public_key     = string
    cloud_init_tpl = string
    master_id      = string
    sleep_time     = string
  }))

}
variable "worker_to_master_private_key" {
  type = string
}
variable "worker_to_master_public_key" {
  type = string

}
variable "wait_for_workers" {
  type = string

}
