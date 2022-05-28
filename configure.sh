#!/bin/bash

set -xeu

EXTRA_DNS=ipfs.aflitos.net

if [[ "$USER" != "ipfs" ]]; then
	echo "run as ipfs user"
	echo "sudo su - ipfs \$PWD/$0"
	exit 1
fi

echo "CONFIGURING"
echo "USER $USER"
echo "HOME $HOME"
echo "PWD  $PWD"

# ipfs init [--algorithm=<algorithm> | -a] [--bits=<bits> | -b] [--empty-repo | -e] [--profile=<profile> | -p] [--]
#            [<default-config>]

if [[ ! -f "$HOME/.ipfs/config" ]]; then
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
ipfs config --json Datastore.StorageMax '"10GB"'


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



if [[ ! -f "$HOME/.ipfs/swarm.key" ]]; then
	echo -e "/key/swarm/psk/1.0.0/\n/base16/\n`tr -dc 'a-f0-9' < /dev/urandom | head -c64`" > $HOME/.ipfs/swarm.key
	chmod 400 $HOME/.ipfs/swarm.key
fi

PEER_ID=`jq -r ".Identity.PeerID" $HOME/.ipfs/config`
PUBLIC_IP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
PUBLIC_HOSTNAME=`curl http://169.254.169.254/latest/meta-data/public-hostname`

echo "PEER_ID         ${PEER_ID}"
echo "PUBLIC_IP       ${PUBLIC_IP}"
echo "PUBLIC_HOSTNAME ${PUBLIC_HOSTNAME}"

#ipfs bootstrap add /ip4/127.0.0.1/tcp/4001/p2p/${PEER_ID}
#ipfs bootstrap add /ip4/${PUBLIC_IP}/tcp/4001/p2p/${PEER_ID}
#ipfs bootstrap add /ip4/${PUBLIC_IP}/udp/4001/quic/p2p/${PEER_ID}
#ipfs bootstrap add /dnsaddr/${PUBLIC_HOSTNAME}/p2p/${PEER_ID}

ipfs config show | jq .Bootstrap


# https://docs.ipfs.io/how-to/best-practices-for-ipfs-builders/
# https://github.com/ipfs/go-ipfs/blob/master/docs/experimental-features.md#experimental-features-of-go-ipfs
#ipfs add --cid-version 1
#ipfs add --raw-leaves
ipfs config --json Pubsub.Enabled true
ipfs config --json Ipns.UsePubsub true
ipfs config --json Experimental.P2pHttpProxy true
ipfs config --json Experimental.Libp2pStreamMounting true
ipfs config --json Experimental.FilestoreEnabled true
#ipfs config --json Addresses.API '"/ip4/0.0.0.0/tcp/5001"'
ipfs config --json Addresses.Gateway '"/ip4/0.0.0.0/tcp/8080"'

# means that you force your node to be private
# If no private network is configured, the daemon will fail to start.
#export LIBP2P_FORCE_PNET=1
#ipfs daemon

ipfs config show | jq .

cat <<CAT > $HOME/bootstrap.txt
ipfs bootstrap rm --all

ipfs bootstrap add /ip4/${PUBLIC_IP}/tcp/4001/p2p/${PEER_ID}
ipfs bootstrap add /ip4/${PUBLIC_IP}/udp/4001/quic/p2p/${PEER_ID}
ipfs bootstrap add /dnsaddr/${PUBLIC_HOSTNAME}/p2p/${PEER_ID}
ipfs bootstrap add /dnsaddr/${EXTRA_DNS}/p2p/${PEER_ID}

ipfs bootstrap list
CAT

echo "BOOTSTRAP ADDRESSES"
cat $HOME/bootstrap.txt

#sudo systemctl stop   ipfs || true
#sudo systemctl status ipfs
#sudo systemctl start  ipfs
#sudo systemctl status ipfs
