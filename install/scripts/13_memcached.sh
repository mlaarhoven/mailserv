#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

# add pidfile to flags
pkg_add -v -m  memcached--

# info:
# /usr/local/share/doc/pkg-readmes/memcached

# add missing network services
if [ `grep -i memcache /etc/services | wc -l` -eq 0 ]; then
cat <<EOF >> /etc/services
memcache        11211/tcp       memcached       # Memory cache service
memcache        11211/udp       memcached       # Memory cache service
EOF
fi

rcctl enable memcached
rcctl set memcached flags `rcctl get memcached flags` --pidfile=/var/run/memcached/memcached.pid
rcctl start  memcached
