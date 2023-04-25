#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

# info
# https://obsd.solutions/en/blog/2022/03/04/openbsd-acme-client-70-for-letsencrypt-certificates/
# /etc/examples/acme-client.conf

# Create config from example
cp -p /etc/examples/acme-client.conf /etc/
sed -i -e '/^domain example.com {$/,$d' /etc/acme-client.conf
cat <<EOF >> /etc/acme-client.conf
domain `hostname` {    
    domain key "/etc/ssl/private/server.key"
    domain full chain certificate "/etc/ssl/server.crt"
    sign with letsencrypt    
    challengedir "/var/www/acme"
}
EOF

# Remove self signed cert+key
rm /etc/ssl/private/server.key
rm /etc/ssl/server.crt

# Use acme-client to make key and get cert from letsencrypt
acme-client `hostname`

# Reload nginx to use new certificate
rcctl reload nginx

# Renew via cron
cat <<EOF >> /etc/crontab
# Renew certificate
~       0       *       *       *       root    acme-client `hostname` && rcctl reload nginx
EOF
