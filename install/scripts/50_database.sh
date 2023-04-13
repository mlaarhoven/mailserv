#!/bin/sh

/usr/local/bin/mysqladmin ping >/dev/null 2>&1
while [ $? -ne 0 ]; do
  sleep 1; /usr/local/bin/mysqladmin ping >/dev/null 2>&1
done
# We now know that the database is running

case $1 in

  (install):
    echo -n "  creating databases"
    unset VERSION
    /usr/local/bin/mysql -e "grant select on mail.* to 'postfix'@'localhost' identified by 'postfix';"
    /usr/local/bin/mysql -e "grant all privileges on mail.* to 'mailadmin'@'localhost' identified by 'mailadmin';"

    cd /var/mailserv/admin && /usr/local/bin/rake -s db:setup RAILS_ENV=production
    cd /var/mailserv/admin && /usr/local/bin/rake -s db:migrate RAILS_ENV=production

    echo "."
    ;;

  (upgrade):
    echo -n "  Updating database schema"
    # Update the database
    cd /var/mailserv/admin && /usr/local/bin/rake RAILS_ENV=production db:migrate
    echo "."
    ;;

esac
