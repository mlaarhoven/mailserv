#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

# add pidfile to flags
pkg_add -v -m  memcached--

# info:
# /usr/local/share/doc/pkg-readmes/memcached

rcctl enable memcached
rcctl set memcached flags `rcctl get memcached flags` --pidfile=/var/run/memcached/memcached.pid
rcctl start  memcached
