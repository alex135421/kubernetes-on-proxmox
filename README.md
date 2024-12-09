# Terraform Kubernetes Deployment for Proxmox

## Description

A small terraform project to deploy kubernetes on proxmox with master and workers for test environments. the install uses kubeadm, containerd and calico as network add-on

## Prerequisites

- A cloud init template from the proxmox guide: https://pve.proxmox.com/wiki/Cloud-Init_Support .
  Issues to shutdown vms with terraform may be because image doesn't have qemu guest agent on it. To fix it try to run the commands below on the node the disk image is present before setting the disk to the cloud init image.

```
sudo apt install libguestfs-tools -y
virt-customize -a *the-image*.img --install qemu-guest-agent,ncat,net-tools,bash-completion
qemu-img resize *the-image*.img 20G
```

- Private and public key pairs should be created, the same may be used for all various parts but recommended to separate for at least two pairs, one should go to connect to vms from local pc and other from worker to master.

- Since sensitive data passed down to `terraform.tfvars` , it's in the gitignore file and should be created when the git cloned.

- Proxmox provider credentials should be added and proxmox url in providers should be changed. Based on terraform provider: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs

## Variables

- A vm map variable that will include all parameters to create the vms and copy the cloud init data

```
vm_map = {
  "key1" = {
    vm_name        = "vm name used for creation and hostname"
    vm_user        = "vm user"
    vm_storage     = "where to create vm"
    vm_disk_size   = "root disk size"
    vm_sockets     = "number of sockets"
    vm_cores       = "number of cores"
    vm_memory      = "memory size in MB"
    vm_ci_storage  = "where to store the cloud-init disk copy"
    node_ip        = "node ip used to make operations for file transfers and stores cloud-init configs"
    kub_type       = "master|worker"
    pve_node       = "name of the node for vm creation"
    pve_node_pass  = "node pass to ssh to"
    ci_iso_storage = "the source of cloud-init image"
    ip_addr        = "ip for the vm"
    public_key     = "public key to connect to vm(used only by external file for example from ssh-keygen )"
    cloud_init_tpl = "the name of the cloud init template machine"
    master_id      = "master key from vm_map"
    sleep_time 	   = "worker sleep time waiting for master to be ready"
  }
}
```

- A ssh key pair between workers and masters.

```
worker_to_master_private_key = "private key string"
worker_to_master_public_key = "public key string"
```

- A wait time for workers to be available before passing the private key, shouldn't be more then `sleep_time` in vm_map. Depends on the speed of the proxmox, if the server takes longer to create parallel vms the time needs to be adjusted

```
wait_for_workers = " wait time for workers vm uptime."
```

## Templates and scripts

### Templates:

- `kub-master.tftpl` is a user cloud init for kubernetes master, it installs and initializes a master server when choosing `kub_type` in vm_map. It gets the parameter from `kub-servers.tf`
- `kub-worker.tftpl` is a user cloud init for kubernetes worker, it uses the same parameters as the master from the tf file but runs a script in its `runcmd` section to wait for master to be available
- `kub-network.tftpl` is a network cloud init which is used for all the servers only changing the ip based on vm_map data.

### Scripts

- `vms-ids.sh` produces vm ids between the range 100-1000, it removes any id that exists(The range could be changed). the script produces the ids on the node. this script meant for dealing with the race condition for parallel vm creation.

## Notes

- The `common.tf` file uses the vm_map variable to create and copy to the node, specified in the parameter for the each vm, the data of each cloud init and create a cloud init disk
- `vm_id.tf` is for creating a list of available vm ids, because of the use of for_each there is a race condition with the proxmox api for creating a vm with the same id for each instance in the resource.
- The join token is saved in `/tmp/worker-join.sh` on the master server.
- While changing the map `vm_map` will not affect other servers, master servers should be cleaned up if a worker is removed.
- Depends on the deployed hardware but recommended `sleep_time` should be at least 5 minutes.
