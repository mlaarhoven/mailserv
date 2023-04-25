#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

mkdir -p /var/db/spamassassin
pkg_add -v -m \
        p5-Mail-SPF \
        p5-Mail-SpamAssassin

# info
# /usr/local/share/doc/pkg-readmes/p5-Mail-SpamAssassin


# create mysql database "spamcontrol"
echo "create database spamcontrol;" | mysql
/usr/local/bin/mysql spamcontrol < /usr/local/share/doc/SpamAssassin/sql/bayes_mysql.sql
/usr/local/bin/mysql spamcontrol < /usr/local/share/doc/SpamAssassin/sql/awl_mysql.sql
# spamcontrol user+permissions
/usr/local/bin/mysql spamcontrol < /var/mailserv/install/templates/sql/spamcontrol.sql
       
# mail.userpref
/usr/local/bin/mysql mail < /usr/local/share/doc/SpamAssassin/sql/userpref_mysql.sql
# add GLOBAL userprefs
/usr/local/bin/mysql mail < /var/mailserv/install/templates/sql/mail.sql

install -m 644 /var/mailserv/install/templates/spamassassin_local.cf /etc/mail/spamassassin/local.cf


rcctl enable spamassassin
rcctl set spamassassin flags -u _spamdaemon -P -s mail -xq -r /var/run/spamassassin.pid -i 127.0.0.1
rcctl start  spamassassin
