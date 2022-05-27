#!/bin/bash

set -xeu

# https://dist.ipfs.io/
IPFS_VER=v0.12.2

DO_UPDATE=0



if [[ "$DO_UPDATE" == "1" ]]; then
	sudo apt clean all
	sudo apt update
	sudo apt autoremove
	sudo apt update
	sudo apt upgrade
	sudo apt autoremove

	sudo apt-get install tar wget jq
fi



if [[ -f "/usr/local/bin/ipfs" ]]; then
	echo ipfs already exists
	echo delete /usr/local/bin/ipfs to update
else
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
fi



if [[ -d "/home/ipfs" ]]; then
	echo "ipfs already exists"
else
	echo "creating ipfs user"
	sudo adduser ipfs
fi


if [[ -f "/etc/systemd/system/ipfs.service" ]]; then
	echo "systemd already configured: /etc/systemd/system/ipfs.service"
	echo "RUN: sudo systemctl start ipfs"
else
	echo "configuring systemd"
	cat <<CAT > /tmp/ipfs.service
[Unit]
Description=IPFS Daemon
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ipfs daemon --enable-namesys-pubsub
ExecStop=/usr/local/bin/ipfs shutdown
User=ipfs
Restart=always

[Install]
WantedBy=multi-user.target
CAT

sudo mv /tmp/ipfs.service /etc/systemd/system/ipfs.service

cat /etc/systemd/system/ipfs.service

sudo systemctl daemon-reload
sudo systemctl enable ipfs
#sudo systemctl start ipfs
sudo systemctl status ipfs
fi


ipfs version

