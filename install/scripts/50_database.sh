#!/bin/sh


case $1 in

  (install):
    echo -n "  creating databases"
    unset VERSION
    


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
