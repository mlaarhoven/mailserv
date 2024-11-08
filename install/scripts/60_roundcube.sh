#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I roundcubemail rcube-contextmenu

# info
# /usr/local/share/doc/pkg-readmes/roundcubemail


basedir="/var/www/roundcubemail"

# create database
/usr/local/bin/mysqladmin create webmail
/usr/local/bin/mysql webmail < ${basedir}/SQL/mysql.initial.sql
/usr/local/bin/mysql -e "GRANT ALL PRIVILEGES ON webmail.* TO 'webmail'@'localhost' IDENTIFIED BY 'webmail'"
/usr/local/bin/mysql -e "FLUSH PRIVILEGES"

# resolv+ssl+mime in chroot
install -D -m 444 -o root -g wheel /etc/hosts                   /var/www/etc/hosts
install    -m 444 -o root -g wheel /etc/resolv.conf             /var/www/etc/
install    -m 444 -o root -g bin   /usr/share/misc/mime.types   /var/www/etc/
install -D -m 444 -o root -g bin   /etc/ssl/cert.pem            /var/www/etc/ssl/cert.pem
install    -m 444 -o root -g bin   /etc/ssl/openssl.cnf         /var/www/etc/ssl/


#remove roundcube installer
#Needed for bin/upgrade.sh
#rm -r ${basedir}/installer

echo "Installing Configuration"
# use default config
# cp /var/www/roundcubemail/config/config.inc.php.sample /var/www/roundcubemail/config/config.inc.php
# diff /var/www/roundcubemail/config/config.inc.php.sample /var/www/roundcubemail/config/config.inc.php

# connect to mysql database
sed -i "/^\$config\['db_dsnw'] =/s/=.*$/= 'mysql:\/\/webmail:webmail@localhost\/webmail';/" /var/www/roundcubemail/config/config.inc.php

# create random des_key (avoid asc 39 ' and asc 47 /)
deskey=`jot -r -c 24 48 126 | rs -g0`
sed -i "/^\$config\['des_key'] =/s/=.*$/= '${deskey}';/"  /var/www/roundcubemail/config/config.inc.php

# Change localhost to hostname so certificate matches
sed -i "/^\$config\['smtp_host']/s/=.*$/= 'tls:\/\/%n:587';/" /var/www/roundcubemail/config/config.inc.php
#DEBUG
#sed -i '/smtp_host/a\
#$config['"'smtp_debug'"'] = true;
#'                                                       /var/www/roundcubemail/config/config.inc.php

cat <<EOF >> ${basedir}/config/config.inc.php

// Log to syslog
\$config['log_driver'] = 'syslog';
// Log successful/failed logins
\$config['log_logins'] = true;

// Use memcached
\$config['imap_cache'] = 'memcached';
\$config['memcache_hosts'] = ['localhost:11211'];

// Session lifetime in minutes
// default=10. 1440=24h 
// \$config['session_lifetime'] = 1440;

// Many identities with possibility to edit all params but not email address
\$config['identities_level'] = 1;

// Store spam and archive messages in this mailbox
\$config['junk_mbox'] = 'Spam';
\$config['archive_mbox'] = 'Archives';

// Compose html formatted messages on forward or reply to HTML message
\$config['htmleditor'] = 3;

// Autosave every minute
\$config['draft_autosave'] = 60;

// Compact INBOX on logout
\$config['logout_expunge'] = true;

// Enables display of email address with name
\$config['message_show_email'] = true;

EOF



# Add active plugins
perl -0777 -pi -e "s/$config\['plugins'\] =.*?\];/$config\['plugins'\] = \['archive','contextmenu','emoticons','managesieve','markasjunk','password','persistent_login','sauserprefs','vcard_attachments','zipdownload'\];/s"  \
    /var/www/roundcubemail/config/config.inc.php


## managesieve plugin
# use default config
# cp /var/www/roundcubemail/plugins/managesieve/config.inc.php.dist /var/www/roundcubemail/plugins/managesieve/config.inc.php
# diff /var/www/roundcubemail/plugins/managesieve/config.inc.php.dist /var/www/roundcubemail/plugins/managesieve/config.inc.php
# Allow users only one rulesets
sed -i "/^\$config\['managesieve_disabled_actions'] =/s/=.*$/= ['list_sets'];/"     /var/www/roundcubemail/plugins/managesieve/config.inc.php
# default name of list
sed -i "/^\$config\['managesieve_script_name'] =/s/=.*$/= 'dovecot';/"              /var/www/roundcubemail/plugins/managesieve/config.inc.php
#DEBUG
#sed -i "/^\$config\['managesieve_debug'] =/s/=.*$/= true;/"                         /var/www/roundcubemail/plugins/managesieve/config.inc.php


## password plugin
# use default config
# cp /var/www/roundcubemail/plugins/password/config.inc.php.dist /var/www/roundcubemail/plugins/password/config.inc.php
# diff /var/www/roundcubemail/plugins/password/config.inc.php.dist /var/www/roundcubemail/plugins/password/config.inc.php
# password driver: mysql
sed -i "/^\$config\['password_db_dsn'] =/s/=.*$/= 'mysql:\/\/webmail:webmail@localhost\/mail';/"    /var/www/roundcubemail/plugins/password/config.inc.php
sed -i "/^\$config\['password_query'] =/s/=.*$/= 'UPDATE users SET password=%p WHERE email=%u AND password=%o LIMIT 1';/" /var/www/roundcubemail/plugins/password/config.inc.php
# grant mysql privileges
/usr/local/bin/mysql -e "GRANT SELECT,UPDATE ON mail.users TO 'webmail'@'localhost'"
/usr/local/bin/mysql -e "FLUSH PRIVILEGES"
# password strength driver: HIBP
sed -i "/^\$config\['password_strength_driver'] =/s/=.*$/= 'pwned';/"                               /var/www/roundcubemail/plugins/password/config.inc.php
sed -i "/^\$config\['password_minimum_score'] =/s/=.*$/= 3;/"                                       /var/www/roundcubemail/plugins/password/config.inc.php


## persistent_login plugin
# https://github.com/mfreiholz/persistent_login
ftp -Vmo - https://github.com/mfreiholz/persistent_login/archive/refs/tags/version-5.3.0.tar.gz | tar -zxf - -C /var/www/roundcubemail/plugins -s /persistent_login-version-[0-9\.]*/persistent_login/
# use default config
cp /var/www/roundcubemail/plugins/persistent_login/config.inc.php.dist /var/www/roundcubemail/plugins/persistent_login/config.inc.php
# diff /var/www/roundcubemail/plugins/persistent_login/config.inc.php.dist /var/www/roundcubemail/plugins/persistent_login/config.inc.php
# Use tokens
sed -i "/ifpl_use_auth_tokens/s/=.*$/= true;/"     /var/www/roundcubemail/plugins/persistent_login/config.inc.php
# create table to store tokens
cat /var/www/roundcubemail/plugins/persistent_login/sql/mysql.sql | /usr/local/bin/mysql webmail


## sauserprefs plugin
# https://packagist.org/packages/johndoh/sauserprefs
# Download release 1.20.1
ftp -Vmo - https://github.com/johndoh/roundcube-sauserprefs/archive/refs/tags/1.20.1.tar.gz | tar zxf - -C ${basedir}/plugins/
mv ${basedir}/plugins/roundcube-sauserprefs-1.20.1 ${basedir}/plugins/sauserprefs
# use sample config
cp ${basedir}/plugins/sauserprefs/config.inc.php.dist ${basedir}/plugins/sauserprefs/config.inc.php
# diff /var/www/roundcubemail/plugins/sauserprefs/config.inc.php.dist /var/www/roundcubemail/plugins/sauserprefs/config.inc.php
# spamassassin database settings
sed -i "/^\$config\['sauserprefs_db_dsnw'] =/s/=.*$/= 'mysql:\/\/mailadmin:mailadmin@127.0.0.1\/mail';/"    /var/www/roundcubemail/plugins/sauserprefs/config.inc.php
# username of the global or default settings user in the database
sed -i "/^\$config\['sauserprefs_global_userid'] =/s/=.*$/= '@GLOBAL';/"                                    /var/www/roundcubemail/plugins/sauserprefs/config.inc.php
# don't allow these sections to be overriden by the user
sed -i "/^\$config\['sauserprefs_dont_override'] =/s/=.*$/= ['{bayes}','{tests}','{headers}'];/"            /var/www/roundcubemail/plugins/sauserprefs/config.inc.php
# SpamAssassin Version 4
sed -i "/^\$config\['sauserprefs_sav4'] =/s/=.*$/= true;/"                                                  /var/www/roundcubemail/plugins/sauserprefs/config.inc.php
# default settings
# these are overridden by @GLOBAL and user settings from the database
sed -i "/rewrite_header Subject/s/=>.*$/=> '[SPAM _SCORE_]',/"                                              /var/www/roundcubemail/plugins/sauserprefs/config.inc.php
sed -i "/report_safe/s/=>.*$/=> 0,/"                                                                        /var/www/roundcubemail/plugins/sauserprefs/config.inc.php




# TODO only skin "elastic" is installed

# taskbar = File.read("#{basedir}/skins/classic/includes/taskbar.html")
# File.open("#{basedir}/skins/classic/includes/taskbar.html", "w") do |f|
#   taskbar.each do |line|
#     if line =~ /\<div id="taskbar"\>/
#       f.puts line
#       f.puts "<a href=\"../../../account/auth/autologin?id=<roundcube:var name='request:roundcube_sessid' />\">Admin</a>"
#     elsif line =~ /account\/auth\/autologin/
#       next
#     else
#       f.puts line
#     end
#   end
# end

# taskbar = File.read("#{basedir}/skins/larry/includes/header.html")
# File.open("#{basedir}/skins/larry/includes/header.html", "w") do |f|
#   taskbar.each do |line|
#     if line =~ /\<div id="taskbar" class="topright"\>/
#       f.puts line
#       f.puts "<a href=\"../../../account/auth/autologin?id=<roundcube:var name='request:roundcube_sessid' />\">Admin</a>"
#     elsif line =~ /account\/auth\/autologin/
#       next
#     else
#       f.puts line
#     end
#   end
# end



echo "Finished\n\n"
echo "If you have updated, please have a look at ${basedir}/SQL/mysql"
echo "and apply as needed.\n\n"
echo "Also, please test the plugins (especially sieve/filter, spam and password)."
echo "This is especially true if you have installed a new major release.\n\n"
