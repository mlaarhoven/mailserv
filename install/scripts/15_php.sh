#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

## PHP
pkg_add -v -m -I \
    php-8.1.16 \
    php-intl-8.1.16 \
    php-mysqli-8.1.16 \
    php-pdo_mysql-8.1.16 \
    php-gd-8.1.16

# info
# /usr/local/share/doc/pkg-readmes/php-8.1

# Create symlinks for all installed php extensions
cd /etc/php-8.1.sample
for i in *; do ln -sf ../php-8.1.sample/$i ../php-8.1/; done

# Install our local changes to php.ini
#TODO /usr/bin/install -m 644 /var/mailserv/install/templates/php-mailserv.ini /etc/php-8.1/mailserv.ini

# Change options in php-fpm.conf
sed -i '/pid = run\/php-fpm.pid/s/^;//' /etc/php-fpm.conf
sed -i '/pm\.max_requests/s/^;//'       /etc/php-fpm.conf
#sed -i '/listen.mode/s/0660/0666/'      /etc/php-fpm.conf

# Make php easier to run from CLI
ln -s /usr/local/bin/php-8.1 /usr/local/bin/php

rcctl enable php81_fpm
rcctl start  php81_fpm
