#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m sqlgrey

# /usr/local/share/examples/sqlgrey/README


# sqlgrey
# cp -p /usr/local/share/examples/sqlgrey/sqlgrey.conf /etc/sqlgrey/sqlgrey.conf
# diff /usr/local/share/examples/sqlgrey/sqlgrey.conf /etc/sqlgrey/sqlgrey.conf

## Socket
#sed -i '/^# inet = 2501/s/^# //'    /etc/sqlgrey/sqlgrey.conf

## Database settings
sed -i '/^# db_type/s/^# //'        /etc/sqlgrey/sqlgrey.conf
sed -i '/^db_type/s/ .*$/ = MariaDB/'   /etc/sqlgrey/sqlgrey.conf
#db_name = sqlgrey
#db_host = localhost
#db_port = default
#db_user = sqlgrey
sed -i '/^# db_pass/s/^# //'        /etc/sqlgrey/sqlgrey.conf
sed -i '/^db_pass/s/ .*$/ = sqlgrey/' /etc/sqlgrey/sqlgrey.conf


# create databbase and user
/usr/local/bin/mysqladmin create sqlgrey
/usr/local/bin/mysql -e "grant all privileges on sqlgrey.* to 'sqlgrey'@'localhost' identified by 'sqlgrey';"

# create files to store whitelists
touch /etc/sqlgrey/clients_fqdn_whitelist.local 
touch /etc/sqlgrey/clients_ip_whitelist.local 

rcctl enable sqlgrey
rcctl start  sqlgrey
  
sleep 2
/usr/local/bin/mysql sqlgrey -e "alter table connect add id int primary key auto_increment first;"
