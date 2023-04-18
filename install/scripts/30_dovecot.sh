#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I \
    dovecot \
    dovecot-pigeonhole \
    dovecot-mysql

# info
# /usr/local/share/doc/pkg-readmes/dovecot
# /etc/login.conf.d/dovecot

template="/var/mailserv/install/templates"
install -m 644 ${template}/dovecot.conf /etc/dovecot/local.conf
# use auth-sql
sed -i '/auth-system.conf.ext/s/^/#/g' /etc/dovecot/conf.d/10-auth.conf
sed -i '/auth-sql.conf.ext/s/^#//g' /etc/dovecot/conf.d/10-auth.conf
install -m 644 ${template}/dovecot-sql.conf /etc/dovecot/dovecot-sql.conf.ext

rcctl enable dovecot


#
# Making dovecot-lda deliver setuid root
# (needed for delivery to different userids)
#
touch /var/log/imap
chgrp _dovecot /usr/local/libexec/dovecot/dovecot-lda
chmod 4750 /usr/local/libexec/dovecot/dovecot-lda
mkdir -p /var/mailserv/mail

#---------------------------------------------------------------
#  increase openfiles limit to 1024 ( obsd usualy runs 128 )
#  necessary to dovecot start up
#  (when server reboot limits are read from login.conf, sysctl.conf) 
#---------------------------------------------------------------
maxfilestest=$( ulimit -n )

if [ $maxfilestest -lt 1024 ];
  then
    echo " "
    echo " setting openfiles-max to 1024 "
    echo " "
    ulimit -n 1024
fi
