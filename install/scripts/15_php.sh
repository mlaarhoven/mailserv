#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

## PHP
pkg_add -v -m -I \
    php%8.2 \
    php-curl%8.2 \
    php-gd%8.2 \
    php-intl%8.2 \
    php-mysqli%8.2 \
    php-pdo_mysql%8.2 \
    php-pspell%8.2 \
    php-zip%8.2 \
    pecl82-imagick \
    pecl82-memcached

# info
# /usr/local/share/doc/pkg-readmes/php-8.2

# Create symlinks for all installed php extensions
cd /etc/php-8.2.sample
for i in *; do ln -sf ../php-8.2.sample/$i ../php-8.2/; done

# Install our local changes to php.ini
#  memcached
sed -i '/session.save_handler =/s/files/memcached/'     /etc/php-8.2.ini
sed -i '/session.save_path =/s/\/tmp/127.0.0.1:11211/'  /etc/php-8.2.ini
sed -i '/session.save_path =/s/^;session/session/'      /etc/php-8.2.ini
#  upload
sed -i '/upload_max_filesize =/s/=.*$/= 16M/'           /etc/php-8.2.ini
sed -i '/post_max_size =/s/=.*$/= 16M/'                 /etc/php-8.2.ini
#  mysql
sed -i '/mysqli.default_socket =/s/=.*$/= \/var\/run\/mysql\/mysql.sock/'   /etc/php-8.2.ini
sed -i '/mysqli.default_socket =/s/=.*$/= \/var\/www\/var\/run\/mysql\/mysql.sock/'   /etc/php-8.2.ini

#TODO
#max_execution_time = 120       # default = 30
#max_input_time = 120           # default = 60
#default_socket_timeout = 120   # default = 60
#allow_url_fopen = On           # default = off



# Change options in php-fpm.conf
sed -i '/pid = run\/php-fpm.pid/s/^;//' /etc/php-fpm.conf
sed -i '/pm\.max_requests/s/^;//'       /etc/php-fpm.conf
#sed -i '/listen.mode/s/0660/0666/'      /etc/php-fpm.conf

# Make php easier to run from CLI
ln -s /usr/local/bin/php-8.2 /usr/local/bin/php


cat <<EOF >> /etc/newsyslog.conf
/var/log/php-fpm.log                    600  5     300  *     Z
EOF


rcctl enable php82_fpm
rcctl start  php82_fpm
