#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

## PHP
pkg_add -v -m -I \
    php-8.1.16 \
    php-intl-8.1.16 \
    php-mysqli-8.1.16 \
    php-pdo_mysql-8.1.16 \
    php-gd-8.1.16 \

# info
# /usr/local/share/doc/pkg-readmes/php-8.1

# Create symlinks for all installed php extensions
cd /etc/php-8.1.sample
for i in *; do ln -sf ../php-8.1.sample/$i ../php-8.1/; done

# Install our local changes to php.ini
/usr/bin/install -m 644 /var/mailserv/install/templates/php-mailserv.ini /etc/php-8.1/mailserv.ini

# Install php-fpm.conf
/usr/bin/install -m 644 /var/mailserv/install/templates/php-fpm.conf /etc/ 

# Make php easier to run from CLI
ln -s /usr/local/bin/php-8.1 /usr/local/bin/php

rcctl enable php81_fpm
rcctl start  php81_fpm


## PHPMYADMIN
pkg_add -v -m -I phpMyAdmin

# info
# /usr/local/share/doc/pkg-readmes/phpMyAdmin

sed -i '/cfg/s/cookie/config/g' /var/www/phpMyAdmin/config.inc.php
sed -i '/cfg/s/localhost/127.0.0.1/g' /var/www/phpMyAdmin/config.inc.php
sed -i '/AllowNoPassword/s/false/true/g' /var/www/phpMyAdmin/config.inc.php

