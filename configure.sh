#!/bin/bash

set -xeu

if [[ "$USER" != "ipfs" ]]; then
	echo "run as ipfs user"
	echo "sudo su ipfs $0"
	exit 1
fi

echo "CONFIGURING"


# ipfs init [--algorithm=<algorithm> | -a] [--bits=<bits> | -b] [--empty-repo | -e] [--profile=<profile> | -p] [--]
#            [<default-config>]

if [[ ! -f "~/.ipfs/config" ]]; then
	ipfs init --profile=server
fi

TS=`date "+%Y-%m-%d"`


# https://medium.com/@s_van_laar/deploy-a-private-ipfs-network-on-ubuntu-in-5-steps-5aad95f7261b
# https://docs.ipfs.io/how-to/modify-bootstrap-list/
ipfs bootstrap list > ipfs_backup_bootstrap_${TS}
ipfs bootstrap rm --all
#ipfs bootstrap add --default
#cat save | ipfs bootstrap add

# 1. disable mDNS discovery
ipfs config --json Discovery.MDNS.Enabled false
ipfs config --json Datastore.StorageMax 10GB


# 2. filter out local network addresses
ipfs config --json Swarm.AddrFilters '[
  "/ip4/10.0.0.0/ipcidr/8",
  "/ip4/100.64.0.0/ipcidr/10",
  "/ip4/169.254.0.0/ipcidr/16",
  "/ip4/172.16.0.0/ipcidr/12",
  "/ip4/192.0.0.0/ipcidr/24",
  "/ip4/192.0.0.0/ipcidr/29",
  "/ip4/192.0.0.8/ipcidr/32",
  "/ip4/192.0.0.170/ipcidr/32",
  "/ip4/192.0.0.171/ipcidr/32",
  "/ip4/192.0.2.0/ipcidr/24",
  "/ip4/192.168.0.0/ipcidr/16",
  "/ip4/198.18.0.0/ipcidr/15",
  "/ip4/198.51.100.0/ipcidr/24",
  "/ip4/203.0.113.0/ipcidr/24",
  "/ip4/240.0.0.0/ipcidr/4"
]'

ipfs config show | jq .Bootstrap



if [[ ! -f "~/.ipfs/swarm.key" ]]; then
	PEER_ID=`jq -r ".Identity.PeerID" ~/.ipfs/config`
	PUBLIC_IP=`curl https://ipinfo.io/ip`

	echo "PEER_ID   ${PEER_ID}"
	echo "PUBLIC_IP ${PUBLIC_IP}"

	ipfs bootstrap add /ip4/${PUBLIC_IP}/tcp/4001/p2p/${PEER_ID}

	echo -e "/key/swarm/psk/1.0.0/\n/base16/\n`tr -dc 'a-f0-9' < /dev/urandom | head -c64`" > ~/.ipfs/swarm.key
fi


# means that you force your node to be private
# If no private network is configured, the daemon will fail to start.
export LIBP2P_FORCE_PNET=1
ipfs daemon
