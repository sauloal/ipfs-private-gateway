# IPFS Gateway

<https://blog.ipfs.io/22-run-ipfs-on-a-vps/>


## DNS

```
CNAME  ipfs                    <AWS_HOSTNAME>
CNAME  gateway.ipfs            <AWS_HOSTNAME>
CNAME  bootstrap.ipfs          <AWS_HOSTNAME>
TXT    _dnsaddr.ipfs           dnsaddr=/dns4/ipfs.<HOSTNAME>/tcp/4001/ipfs/<ID>
TXT    _dnsaddr.gateway.ipfs   dnsaddr=/dns4/gateway.ipfs.<HOSTNAME>/tcp/8080/ipfs/<ID>
TXT    _dnsaddr.bootstrap.ipfs dnsaddr=/dns4/bootstrap.ipfs.<HOSTNAME>/tcp/4401/ipfs/<ID>
```

```
dig +short TXT _dnsaddr.ipfs.<HOSTNAME>
dig +short TXT _dnsaddr.gateway.ipfs.<HOSTNAME>
dig +short TXT _dnsaddr.bootstrap.ipfs.<HOSTNAME>
```

```
CNAME  ipfs                     ec2.eu-central-1.compute.amazonaws.com
CNAME  gateway.ipfs             ec2.eu-central-1.compute.amazonaws.com
CNAME  bootstrap.ipfs           ec2.eu-central-1.compute.amazonaws.com
TXT    _dnsaddr.ipfs            dnsaddr=/dns4/ipfs.yourdomain.net/tcp/4001/ipfs/<ID>
TXT    _dnsaddr.gateway.ipfs    dnsaddr=/dns4/gateway.ipfs.yourdomain.net/tcp/8080/ipfs/<ID>
TXT    _dnsaddr.bootstrap.ipfs  dnsaddr=/dns4/bootstrap.ipfs.yourdomain.net/tcp/4001/ipfs/<ID>
```
