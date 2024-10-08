#!/bin/bash

# cspell:ignore mountpoints

disk_mapping_file="/var/lib/snapd/device/disk-mapping.json"
lsblk_tpm_fde_dev="$(
  lsblk --json \
    | jq -r '.blockdevices[] | select(.children[]?.mountpoints[]? == "/run/mnt/ubuntu-seed") | .name'
)"
disk_mapping_dev="$(jq -r '.pc."kernel-path"' "${disk_mapping_file}")"

if [[ "/dev/${lsblk_tpm_fde_dev}" == "${disk_mapping_dev}" ]]; then
  # Send to journal/shell.
  echo "No issue found."

  # Send desktop notification.
  # notify-send "TPM-FDE Check" "No issue found."
else
  # Send to journal/shell.
  echo "Error:   The disk mapping has changed."
  echo "Current: /dev/${lsblk_tpm_fde_dev}"
  echo "Before:  ${disk_mapping_dev}"
  echo "Please check ${disk_mapping_file}."

  # Send desktop notification.
  notify-send "TPM-FDE Check" \
    "Error: The disk mapping has changed. Current: /dev/${lsblk_tpm_fde_dev}, before: ${disk_mapping_dev}. Please check ${disk_mapping_file}."
fi

if [[ $1 == "fix" && "/dev/${lsblk_tpm_fde_dev}" != "${disk_mapping_dev}" ]]; then
  sudo sed --in-place="$(date +%F_%H%M%S).bak" \
    "s/${lsblk_tpm_fde_dev}/${disk_mapping_dev//\/dev\//}/g" \
    "${disk_mapping_file}"

  # Display all files.
  ls -l "${disk_mapping_file}"*
fi
