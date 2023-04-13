#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I rrdtool
template="/var/mailserv/install/templates"
install -m 644 ${template}/rrdmon.conf /etc
/usr/local/bin/ruby /var/mailserv/scripts/rrdmon_create.rb


cat <<EOF >> /etc/crontab
# Collect System stats
*/5     *       *       *       *       root    /var/mailserv/scripts/rrdmon-poll >/dev/null 2>&1

EOF
