#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

mkdir -p /var/db/spamassassin
pkg_add -v -m \
        p5-Mail-SPF \
        p5-Mail-SpamAssassin

# info
# /usr/local/share/doc/pkg-readmes/p5-Mail-SpamAssassin

#cp /usr/local/share/examples/SpamAssassin/* /etc/mail/spamassassin/
#diff /usr/local/share/examples/SpamAssassin/ /etc/mail/spamassassin/
# Show spam score in header
sed -i '/^# rewrite_header/s/^# //'                             /etc/mail/spamassassin/local.cf
sed -i '/^rewrite_header/s/Subject.*$/Subject [SPAM _SCORE_]/'  /etc/mail/spamassassin/local.cf

# Encapsulate spam in an attachment (0=no, 1=yes, 2=safe)
sed -i '/^# report_safe/s/^# //'                                /etc/mail/spamassassin/local.cf
sed -i '/^report_safe/s/ .*$/ 0/'                               /etc/mail/spamassassin/local.cf


# create mysql database "spamcontrol"
echo "create database spamcontrol;" | /usr/local/bin/mysql


## USER PREFS
# https://spamassassin.apache.org/full/4.0.x/doc/Mail_SpamAssassin_Conf.html
# /usr/local/share/doc/SpamAssassin/sql/userpref_mysql.sql/README
# create table mail.userpref (+FIX SQL)
sed '/TYPE/s/TYPE/ENGINE/' /usr/local/share/doc/SpamAssassin/sql/userpref_mysql.sql | /usr/local/bin/mysql mail
# create user. Also used by roundcube/sauserpref plugin
/usr/local/bin/mysql -e "GRANT ALL PRIVILEGES ON mail.* TO 'mailadmin'@'localhost' IDENTIFIED BY 'mailadmin';"
/usr/local/bin/mysql -e "FLUSH PRIVILEGES"
# add GLOBAL userprefs (editable by roundcube/sauserpref plugin)
/usr/local/bin/mysql mail -e "INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL', 'required_score', '5.0', NULL);"
/usr/local/bin/mysql mail -e "INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL', 'rewrite_header Subject', '[SPAM _SCORE_]', NULL);"
/usr/local/bin/mysql mail -e "INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL', 'ok_languages', 'all', NULL);"
/usr/local/bin/mysql mail -e "INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL', 'ok_locales', 'all', NULL);"
/usr/local/bin/mysql mail -e "INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL', 'report_safe', '0', NULL);"    
# TODO?
# INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'trusted_networks', '10.0.0.0/8', NULL);
# INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'trusted_networks', '172.16.0.0/12', NULL);
# INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'trusted_networks', '192.168.0.0/16', NULL);
# /usr/local/bin/mysql mail -e "INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'use_bayes', '1', NULL);"
# /usr/local/bin/mysql mail -e "INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'bayes_auto_learn', '1', NULL);"
# INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'skip_rbl_checks', '0', NULL);
# INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'use_razor2', '0', NULL);
# INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'use_pyzor', '0', NULL);
# INSERT INTO userpref (username, preference, value, prefid) VALUES ('@GLOBAL',  'ok_locales', '1', NULL);
# add user_scores settings
cat <<EOF >> /etc/mail/spamassassin/local.cf

user_scores_dsn                 DBI:MariaDB:mail:localhost
user_scores_sql_username        mailadmin
user_scores_sql_password        mailadmin
EOF


## BAYES
# https://spamassassin.apache.org/full/4.0.x/doc/Mail_SpamAssassin_Plugin_Bayes.html
# /usr/local/bin/mysql spamcontrol < /usr/local/share/doc/SpamAssassin/sql/bayes_mysql.sql
#use_bayes               1  use_bayes ( 0 | 1 )      (default: 1)
#bayes_auto_learn        1  bayes_auto_learn ( 0 | 1 )      (default: 1)
# cat <<EOF >> /etc/mail/spamassassin/local.cf
#
# bayes_store_module              Mail::SpamAssassin::BayesStore::SQL
# bayes_sql_dsn                   DBI:MariaDB:spamcontrol:localhost
# bayes_sql_username              spamassassin
# bayes_sql_password              spamassassin
# EOF
# spamcontrol user+permissions
/usr/local/bin/mysql -e "GRANT SELECT ON spamcontrol.* TO 'spamassassin'@'localhost' identified BY 'spamassassin';"
/usr/local/bin/mysql -e "GRANT SELECT, UPDATE, DELETE, INSERT ON spamcontrol.bayes_token  TO 'spamassassin'@'localhost';"
/usr/local/bin/mysql -e "GRANT SELECT, UPDATE, DELETE, INSERT ON spamcontrol.bayes_vars   TO 'spamassassin'@'localhost';"
/usr/local/bin/mysql -e "GRANT SELECT, DELETE, INSERT         ON spamcontrol.bayes_seen   TO 'spamassassin'@'localhost';"
/usr/local/bin/mysql -e "GRANT SELECT, DELETE, INSERT         ON spamcontrol.bayes_expire TO 'spamassassin'@'localhost';"


## AWL
# https://spamassassin.apache.org/full/4.0.x/doc/Mail_SpamAssassin_Plugin_AWL.html
#/usr/local/bin/mysql spamcontrol < /usr/local/share/doc/SpamAssassin/sql/awl_mysql.sql
#sed -i '/Plugin::AWL/s/^#//'                                    /etc/mail/spamassassin/v310.pre
#cat <<EOF >> /etc/mail/spamassassin/local.cf
#
#auto_whitelist_factory          Mail::SpamAssassin::SQLBasedAddrList 
#user_awl_dsn                    DBI:MariaDB:spamcontrol:localhost
#user_awl_sql_username           spamassassin
#user_awl_sql_password           spamassassin
#user_awl_sql_table              awl
#EOF
# permissions
/usr/local/bin/mysql -e "GRANT SELECT, UPDATE, DELETE, INSERT ON spamcontrol.awl          TO 'spamassassin'@'localhost';"


## TXREP
# https://spamassassin.apache.org/full/4.0.x/doc/Mail_SpamAssassin_Plugin_TxRep.html
#/usr/local/share/doc/SpamAssassin/sql/txrep_mysql.sql
#sed -i '/Plugin::TxRep/s/^#//'                                  /etc/mail/spamassassin/v341.pre


## DECODESHORTURL
# https://spamassassin.apache.org/full/4.0.x/doc/Mail_SpamAssassin_Plugin_DecodeShortURLs.html
#/usr/local/share/doc/SpamAssassin/sql/decodeshorturl_mysql.sql
#sed -i '/Plugin::DecodeShortURLs/s/^#//'                        /etc/mail/spamassassin/v400.pre


## TEXTCAT
# https://spamassassin.apache.org/full/4.0.x/doc/Mail_SpamAssassin_Plugin_TextCat.html
# enable plugin
sed -i '/Plugin::TextCat/s/^#//'                                /etc/mail/spamassassin/v310.pre


/usr/local/bin/mysql -e "FLUSH PRIVILEGES"


rcctl enable spamassassin
rcctl set spamassassin flags -u _spamdaemon -P -s mail -xq -r /var/run/spamassassin.pid -i 127.0.0.1
rcctl start  spamassassin
