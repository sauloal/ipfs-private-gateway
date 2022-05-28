#!/bin/bash

SOURCE_PATH=$(dirname `readlink -f $0`)
source $SOURCE_PATH/config.sh

if [[ -z "${EXTRA_DNS_PREFIX}" ]]; then
	echo "no extra DNS defined"
	exit 1
fi
if [[ -z "${EXTRA_DNS_SUFFIX}" ]]; then
	echo "no extra DNS defined"
	exit 1
fi

set -xeu

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
============
CONFIG PEER
============

ipfs bootstrap rm --all
ipfs bootstrap list #ensure empty
ipfs daemon &
ipfs swarm peers #ensure empty
ipfs shutdown

#ipfs bootstrap add /ip4/${PUBLIC_IP}/tcp/4001/p2p/${PEER_ID}
#ipfs bootstrap add /ip4/${PUBLIC_IP}/udp/4001/quic/p2p/${PEER_ID}
#ipfs bootstrap add /dnsaddr/${PUBLIC_HOSTNAME}/p2p/${PEER_ID}
#ipfs bootstrap add /dnsaddr/bootstrap.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}/p2p/${PEER_ID}
ipfs bootstrap add /dns4/bootstrap.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}/tcp/4001/ipfs/${PEER_ID}
ipfs bootstrap add /dns4/bootstrap.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}/udp/4001/quic/ipfs/${PEER_ID}

ipfs bootstrap list #ensure 1
ipfs daemon &
ipfs swarm peers #ensure ${PEER_ID} is present
ipfs shutdown


============
DNS
============

CNAME  ${EXTRA_DNS_PREFIX}                    ${PUBLIC_HOSTNAME}
CNAME  gateway.${EXTRA_DNS_PREFIX}            ${PUBLIC_HOSTNAME}
CNAME  bootstrap.${EXTRA_DNS_PREFIX}          ${PUBLIC_HOSTNAME}
#TXT    _dnsaddr.${EXTRA_DNS_PREFIX}   dnsaddr=/ip4/${PUBLIC_IP}/tcp/4001/p2p/${PEER_ID}
#TXT    _dnsaddr.bootstrap.${EXTRA_DNS_PREFIX}  dnsaddr=/ip4/${PUBLIC_IP}/tcp/4001/p2p/${PEER_ID}
TXT    _dnsaddr.${EXTRA_DNS_PREFIX}           dnsaddr=/dns4/${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}/tcp/4001/ipfs/${PEER_ID}
TXT    _dnsaddr.gateway.${EXTRA_DNS_PREFIX}   dnsaddr=/dns4/gateway.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}/tcp/8080/ipfs/${PEER_ID}
TXT    _dnsaddr.bootstrap.${EXTRA_DNS_PREFIX} dnsaddr=/dns4/bootstrap.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}/tcp/4001/ipfs/${PEER_ID}

dig +short TXT _dnsaddr.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}
dig +short TXT _dnsaddr.gateway.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}
dig +short TXT _dnsaddr.bootstrap.ipfs.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}

curl -v http://gateway.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX}:8080/ipfs/
nc -zvw10 ${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX} 4001
nc -zvw10 gateway.${EXTRA_DNS_PREFIX}.${EXTRA_DNS_SUFFIX} 4001

============
DEBUG
============

#https://docs.ipfs.io/how-to/troubleshooting/#go-debugging
curl localhost:5001/debug/pprof/goroutine\?debug=2 > ipfs.stacks
curl localhost:5001/debug/pprof/profile > ipfs.cpuprof
curl localhost:5001/debug/pprof/heap > ipfs.heap
curl localhost:5001/debug/vars > ipfs.vars
curl -X POST localhost:5001/api/v0/swarm/peers

ipfs diag sys > ipfs.sysinfo


CAT

echo "BOOTSTRAP ADDRESSES"
cat $HOME/bootstrap.txt

#sudo systemctl stop   ipfs || true
#sudo systemctl status ipfs
#sudo systemctl start  ipfs
#sudo systemctl status ipfs
