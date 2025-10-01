#!/bin/bash
set -euo pipefail

# =============================
# VM Setup Script
# =============================

clear

# ===== Banner =====
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

# ===== Subscription Animation =====
GRN='\033[0;32m'
CYN='\033[0;36m'
NC='\033[0m'

echo -e "${GRN}🔥 Please Subscribe \n${NC}"

for i in {1..3}; do
  echo -ne "${CYN}Subscribing To Zynez"
  for dot in {1..3}; do
    echo -n "."
    sleep 0.3
  done
  echo -ne "\r\033[K"
done
echo -e "${GRN}✅ Thanks for Subscribing to Zynez!${NC}\n"
sleep 1

# ===== VM Config =====
VM_DIR="$HOME/vm"
IMG_FILE="$VM_DIR/ubuntu-cloud.img"
SEED_FILE="$VM_DIR/seed.iso"
MEMORY=32768   # 32GB RAM
CPUS=24
SSH_PORT=2222
DISK_SIZE=100G

mkdir -p "$VM_DIR"
cd "$VM_DIR"

# ===== Dependency Check =====
DEPS=(qemu-system-x86_64 cloud-localds wget)
for cmd in "${DEPS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "[INFO] $cmd not found. Installing..."
        sudo apt update -y
        sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils cloud-image-utils wget
        break
    fi
done

# ===== VM Image Setup =====
if [ ! -f "$IMG_FILE" ]; then
    echo "[INFO] VM image not found, downloading..."
    wget -q https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O "$IMG_FILE"
    qemu-img resize "$IMG_FILE" "$DISK_SIZE"

    # Cloud-init config
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
EOF

    cat > meta-data <<EOF
instance-id: iid-local01
local-hostname: Zynez
EOF

    cloud-localds "$SEED_FILE" user-data meta-data
    echo "[INFO] VM setup complete!"
else
    echo "[INFO] VM image exists, skipping download..."
fi

# ===== Start VM =====
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
