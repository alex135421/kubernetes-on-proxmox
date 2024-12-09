#!/bin/bash
name=$1
pve_vms=$(pvesh get /cluster/resources --type vm --noborder --noheader)
pve_ids=$(qm list | grep -v VMID | awk {'print $1'})
available=()
for vms in {100..1000}; do
  if [[ $pve_ids != *"$vms"* ]]; then
    available+=($vms)
  fi
done
arr_vms=$(
  IFS=,
  echo "${available[*]}"
)
echo "{\"vms\":[$arr_vms]}" >$name
