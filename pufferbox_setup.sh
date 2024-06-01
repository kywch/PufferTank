#!/bin/bash

# REMEMBER TO UPDATE DOCKER PULL FLAG WHEN UPDATING THIS SCRIPT

# Run this script as root. Prerequisites:
#   1. Disable secure boot in BIOS settings! Otherwise, NVIDIA drivers will not work.
#   2. Upgrade system and REBOOT:
#          apt-get update && apt-get upgrade && apt-get dist-upgrade && apt-get install git
#   3. cd /home/puffer && git clone https://github.com/pufferai/puffertank

# Install essentials
apt-get install -y \
    linux-headers-$(uname -r) \
    build-essential \
    openssh-server \
    vim \
    dkms \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg

# Fix sources.list
cp sources.list /etc/apt/sources.list

# Install Tailscale
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi


cat "cd /home/puffer/puffertank && bash docker.sh test" >> /home/puffer/.bashrc

# Docker
if ! command -v docker &> /dev/null; then
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# Update the package list to reflect new repositories
apt-get update -y

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install the NVIDIA driver using the Debian non-free repository
apt-get install -t experimental -y nvidia-driver

echo "Installation complete. Please reboot your system."

# Nvidia container (have to use Debian 11 bullseye for now)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey > /etc/apt/keyrings/nvidia-docker.key
curl -s -L https://nvidia.github.io/nvidia-docker/debian11/nvidia-docker.list > /etc/apt/sources.list.d/nvidia-docker.list
sed -i -e "s/^deb/deb \[signed-by=\/etc\/apt\/keyrings\/nvidia-docker.key\]/g" /etc/apt/sources.list.d/nvidia-docker.list

apt-get update && apt-get install -y nvidia-container-toolkit
systemctl restart docker

# Completion message with instructions
echo -e "Installation complete.\nTo complete installation:\n\
1) Set passwords:\n\
   - passwd puffer\n\
   - passwd root\n\
2) Initialize Tailscale:\n\
   - tailscale up\n\
3) Reboot the machine."
