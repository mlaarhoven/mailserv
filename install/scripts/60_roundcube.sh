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

# create random des_key
deskey=`jot -r -c 24 40 126 | rs -g0`
sed -i "/^\$config\['des_key'] =/s/=.*$/= '${deskey}';/"  /var/www/roundcubemail/config/config.inc.php


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
perl -0777 -pi -e "s/$config\['plugins'\] =.*\];/$config\['plugins'\] = \['archive','contextmenu','emoticons','markasjunk','password','vcard_attachments','zipdownload'\];/s"  \
    /var/www/roundcubemail/config/config.inc.php

# TODO 'sieverules', 'sauserprefs'

# TODO install -m 0644 /var/mailserv/install/templates/roundcube/sieverules/config.inc.php  #{basedir}/plugins/sieverules/
# TODO install -m 0644 /var/mailserv/install/templates/roundcube/sauserprefs/config.inc.php #{basedir}/plugins/sauserprefs/


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
echo "If you have updated, please have a look at #{basedir}/SQL/mysql"
echo "and apply as needed.\n\n"
echo "Also, please test the plugins (especially sieve/filter, spam and password)."
echo "This is especially true if you have installed a new major release.\n\n"
