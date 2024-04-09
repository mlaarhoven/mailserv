#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1
   
pkg_add -v -m -I mariadb-server

# info:
# /usr/local/share/doc/pkg-readmes/mariadb-server
# /usr/local/share/examples/mysql
# /etc/login.conf.d/mysqld

# initialize MariaDB data directory
/usr/local/bin/mariadb-install-db

# TODO check old settings
#template="/var/mailserv/install/templates"
#install -m 644 ${template}/my.cnf /etc
# Use example my.cnf
# cp /usr/local/share/examples/mysql/my.cnf /etc/my.cnf
# diff /usr/local/share/examples/mysql/my.cnf /etc/my.cnf


# Create and use a directory for the MariaDB socket within www chroot
install -d -m 0711 -o _mysql -g _mysql /var/www/var/run/mysql
sed -i '/socket/s/\/var\/run\/mysql\/mysql.sock/\/var\/www\/var\/run\/mysql\/mysql.sock/g' /etc/my.cnf
sed -i '/socket/s/^#//g' /etc/my.cnf

cat <<EOF >> /etc/my.cnf

# Default collation+charset
collation-server = utf8mb4_unicode_ci
init-connect='SET NAMES utf8mb4'
character-set-server = utf8mb4

# Smaller buffers
key_buffer_size=10M
innodb_buffer_pool_size=32M

EOF


# SETUP LOGROTATE
# TODO /usr/local/share/examples/mysql/mysql-log-rotate


rcctl enable mysqld
rcctl set mysqld flags --pid-file=mysql.pid
rcctl start  mysqld

# Secure installation
#mysql_secure_installation --defaults-file=/etc/my.cnf
# Run sql statements instead of running interactive script
# TODO Set the root password
#rootpwd=`jot -r -c 12 32 127 | rs -g0`
#mysql -e "UPDATE mysql.user SET Password=PASSWORD('complex_password') WHERE User='root';"

# Remove anonymous users
mysql -e "DELETE FROM mysql.user WHERE User='';"

# Disallow root login remotely
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

# Remove test database and access to it
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"

# Reload privilege tables now
mysql -e "FLUSH PRIVILEGES;"
