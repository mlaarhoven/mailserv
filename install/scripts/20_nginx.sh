#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I nginx

# info
# /usr/local/share/doc/pkg-readmes/nginx
# /usr/local/share/nginx/nginx.conf

# Use newsyslog to rotate the log files. Replace the standard entries for httpd in /etc/newsyslog.conf
sed -i '/\/var\/www\/logs\/access.log/s/Z .*$/Z \/var\/run\/nginx.pid SIGUSR1/'                /etc/newsyslog.conf
sed -i '/\/var\/www\/logs\/access.log/s/\/var\/www\/logs\/access.log/\/var\/log\/httpd.log\t/' /etc/newsyslog.conf
sed -i '/\/var\/www\/logs\/error.log/s/Z .*$/Z \/var\/run\/nginx.pid SIGUSR1/'                 /etc/newsyslog.conf
sed -i '/\/var\/www\/logs\/error.log/s/\/var\/www\/logs\/error.log/\/var\/log\/httpd.err/'     /etc/newsyslog.conf

template="/var/mailserv/install/templates"
install -m 644 ${template}/nginx.conf /etc/nginx

rcctl enable nginx
#No chroot
#rcctl set nginx flags -u
rcctl start  nginx
