#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I roundcubemail rcube-contextmenu

# info
# /usr/local/share/doc/pkg-readmes/roundcubemail


basedir="/var/www/roundcubemail"

# resolv+ssl in chroot
mkdir -p /var/www/etc/ssl
install -m 444 -o root -g bin /etc/resolv.conf /var/www/etc/
install -m 444 -o root -g bin /etc/ssl/cert.pem /etc/ssl/openssl.cnf /var/www/etc/ssl/

# copy mime.types within chroot
cp -p /usr/share/misc/mime.types /var/www/roundcubemail

#remove roundcube installer
#Needed for bin/upgrade.sh
#rm -r ${basedir}/installer

echo "Installing Configuration"
#TODO compare with config.inc.php.sample
#install -m 0644 /var/mailserv/install/templates/roundcube/conf/config.inc.php        #{basedir}/config/
cp /var/www/roundcubemail/config/config.inc.php.sample /var/www/roundcubemail/config/config.inc.php

#TODO 127.0.0.1??
sed -i "/^\$config\['db_dsnw'] =/s/=.*$/= 'mysql:\/\/webmail:webmail@localhost\/webmail';/" /var/www/roundcubemail/config/config.inc.php

# TODO
cat <<EOF >> /var/www/roundcubemail/config/config.inc.php
\$config['log_driver'] = 'syslog';
// default=LOG_USER
// \$config['syslog_facility'] = LOG_LOCAL0;
\$config['log_logins'] = true;
\$config['memcache_hosts'] = ['127.0.0.1:11211'];
\$config['imap_cache'] = 'memcached';
\$config['mime_types'] = '/roundcubemail/mime.types';
\$config['session_storage'] = 'db';
\$config['draft_autosave'] = 60;

// default=0(never). 1 - Allow from my contacts
// \$config['show_images'] = 1;

// default=0. Or use 4 - always, except when replying to plain text message??
// \$config['htmleditor'] = 2;

// Session lifetime in minutes
// default=10. 1440=24h 
// \$config['session_lifetime'] = 1440;

// Clear Trash on logout
//\$config['logout_purge'] = true;
// Compact INBOX on logout
//\$config['logout_expunge'] = true;
// If true, after message delete/move, the next message will be displayed
//\$config['display_next'] = false;

// IMAP AUTH type (DIGEST-MD5, CRAM-MD5, LOGIN, PLAIN or null to use best server supported one)
\$config['imap_auth_type'] = 'plain';

// enforce connections over https
\$config['force_https'] = true;

// Forces conversion of logins to lower case. 0 - disabled, 1 - only domain part, 2 - domain and local part.
\$config['login_lc'] = 0;

EOF

# plugins
# TODO 'sieverules', 'sauserprefs', 
sed -i "/\$config\['plugins'] =/s/=.*$/= \[ 'vcard_attachments', 'password', 'contextmenu', 'emoticons',/" /var/www/roundcubemail/config/config.inc.php




#depracated? install -m 0644 /var/mailserv/install/templates/roundcube/messagesize/config.inc.php #{basedir}/plugins/messagesize/
# TODO install -m 0644 /var/mailserv/install/templates/roundcube/sieverules/config.inc.php  #{basedir}/plugins/sieverules/
# TODO install -m 0644 /var/mailserv/install/templates/roundcube/sauserprefs/config.inc.php #{basedir}/plugins/sauserprefs/

#install -m 0644 /var/mailserv/install/templates/roundcube/password/config.inc.php    #{basedir}/plugins/password/
cp /var/www/roundcubemail/plugins/password/config.inc.php.dist /var/www/roundcubemail/plugins/password/config.inc.php
sed -i "/^\$config\['password_db_dsn'] =/s/=.*$/= 'mysql:\/\/mailadmin:mailadmin@127.0.0.1\/mail';/" /var/www/roundcubemail/plugins/password/config.inc.php
sed -i "/^\$config\['password_query'] =/s/=.*$/= 'UPDATE users SET password=%p WHERE email=%u AND password=%o LIMIT 1';/" /var/www/roundcubemail/plugins/password/config.inc.php
# TODO? $config['password_strength_driver'] = 'pwned';
# TODO? $config['password_minimum_score'] = 3;



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

/usr/local/bin/mysqladmin create webmail
/usr/local/bin/mysql webmail < /var/www/roundcubemail/SQL/mysql.initial.sql
/usr/local/bin/mysql webmail -e "grant all privileges on webmail.* to 'webmail'@'localhost' identified by 'webmail'"
