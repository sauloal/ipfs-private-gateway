#!/bin/bash

set -xeu

# https://dist.ipfs.io/
IPFS_VER=v0.12.2

sudo apt clean all
sudo apt update
sudo apt autoremove
sudo apt update
sudo apt upgrade
sudo apt autoremove

sudo apt-get install tar wget jq

cd /tmp

if [[ -d "ipfs-gateway" ]]; then
	rm -rfv ipfs-gateway
fi

mkdir -p ipfs-gateway

cd ipfs-gateway

wget --no-clobber https://dist.ipfs.io/go-ipfs/${IPFS_VER}/go-ipfs_${IPFS_VER}_linux-amd64.tar.gz

tar xfv go-ipfs_${IPFS_VER}_linux-amd64.tar.gz

# Move it into your bin. This requires root permissions.
sudo cp go-ipfs/ipfs /usr/local/bin/

cd /tmp

rm -rfv ipfs-gateway


