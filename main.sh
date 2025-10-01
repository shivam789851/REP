#!/bin/bash
set -euo pipefail

# =============================
# Ubuntu 22.04 VM (Auto Setup)
# =============================

clear
cat << "EOF"
/$$$$$$$$       /$$     /$$       /$$   /$$       /$$$$$$$$       /$$   /$$
|_____ $$       |  $$   /$$/      | $$$ | $$      | $$_____/      | $$  / $$
     /$$/        \  $$ /$$/       | $$$$| $$      | $$            |  $$/ $$/
    /$$/          \  $$$$/        | $$ $$ $$      | $$$$$          \  $$$$/ 
   /$$/            \  $$/         | $$  $$$$      | $$__/           >$$  $$ 
  /$$/              | $$          | $$\  $$$      | $$             /$$/\  $$
 /$$$$$$$$          | $$          | $$ \  $$      | $$$$$$$$      | $$  \ $$ 
|________/          |__/          |__/  \__/      |________/      |__/  |__/

                     POWERED BY ZYNEZ
EOF

# =============================
# Configurable Variables
# =============================
VM_DIR="$HOME/vm"
IMG_FILE="$VM_DIR/ubuntu-cloud.img"
SEED_FILE="$VM_DIR/seed.iso"
MEMORY=32768   # 32GB RAM
CPUS=24
SSH_PORT=2222
DISK_SIZE=100G

mkdir -p "$VM_DIR"
cd "$VM_DIR"

# =============================
# VM Image Setup
# =============================
if [ ! -f "$IMG_FILE" ]; then
    echo "[INFO] VM image not found, creating new VM..."
    wget -q https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O "$IMG_FILE"
    qemu-img resize "$IMG_FILE" "$DISK_SIZE"

    # Cloud-init config with hostname = Zynez
    cat > user-data <<EOF
#cloud-config
hostname: Zynez
manage_etc_hosts: true
disable_root: false
ssh_pwauth: true
chpasswd:
  list: |
    root:root
  expire: false
growpart:
  mode: auto
  devices: ["/"]
  ignore_growroot_disabled: false
resize_rootfs: true
runcmd:
 - growpart /dev/vda 1 || true
 - resize2fs /dev/vda1 || true
 - sed -ri "s/^#?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
 - systemctl restart ssh
EOF

    cat > meta-data <<EOF
instance-id: iid-local01
local-hostname: Zynez
EOF

    cloud-localds "$SEED_FILE" user-data meta-data
    echo "[INFO] VM setup complete!"
else
    echo "[INFO] VM image found, skipping setup..."
fi

# =============================
# Start VM
# =============================
echo "[INFO] Starting VM..."
exec qemu-system-x86_64 \
    -enable-kvm \
    -m "$MEMORY" \
    -smp "$CPUS" \
    -cpu host \
    -drive file="$IMG_FILE",format=qcow2,if=virtio \
    -drive file="$SEED_FILE",format=raw,if=virtio \
    -boot order=c \
    -device virtio-net-pci,netdev=n0 \
    -netdev user,id=n0,hostfwd=tcp::"$SSH_PORT"-:22 \
    -nographic
