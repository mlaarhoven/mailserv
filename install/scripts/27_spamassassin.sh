#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m \
        p5-Mail-SPF \
        p5-Mail-SpamAssassin


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
