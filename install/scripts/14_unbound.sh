#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1


### UNBOUND as resolving proxy DNS server
# /var/unbound/etc/unbound.conf
rcctl enable unbound
rcctl start unbound

# get current interface
netif=`netstat -rnf inet | grep default | awk '{print $8}'`

# Don't use dns resolvers from dhcp
cat <<EOF > /etc/dhcpleased.conf
interface $netif {
    ignore dns
}
EOF

# Use local unbound for all rbl dns queries
cat <<EOF > /etc/resolv.conf
nameserver 127.0.0.1
lookup file bind
EOF
