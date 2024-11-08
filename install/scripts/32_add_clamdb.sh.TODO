#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m clamav 

# /usr/local/share/examples/clamav/clamd.conf.sample
# /usr/local/share/examples/clamav/freshclam.conf.sample
# /usr/local/share/examples/clamav/clamav-milter.conf.sample


# clamd
# cp -p /usr/local/share/examples/clamav/clamd.conf.sample /etc/clamd.conf
# diff /usr/local/share/examples/clamav/clamd.conf.sample /etc/clamd.conf

sed -i '/^Example/s/^E/#E/'                /etc/clamd.conf

sed -i '/^#LogSyslog/s/^#//'                /etc/clamd.conf
sed -i '/^#LogFacility/s/^#//'              /etc/clamd.conf

sed -i '/^#PidFile/s/^#//'                  /etc/clamd.conf
sed -i '/^PidFile/s/ .*$/ \/var\/run\/clamd.pid/' /etc/clamd.conf

sed -i '/^#LocalSocket \/tmp/s/^#//'        /etc/clamd.conf

sed -i '/^#MaxConnectionQueueLength/s/^#//' /etc/clamd.conf
# TODO?
#StreamMaxLength 20M
#SelfCheck 1800
#User _postfix


# freshclam
# cp -p /usr/local/share/examples/clamav/freshclam.conf.sample  /etc/freshclam.conf
# diff /usr/local/share/examples/clamav/freshclam.conf.sample  /etc/freshclam.conf
sed -i '/^Example/s/^E/#E/'                /etc/freshclam.conf

sed -i '/^#UpdateLogFile/s/^#//'           /etc/freshclam.conf

sed -i '/^#PidFile/s/^#//'                 /etc/freshclam.conf
sed -i '/^PidFile/s/ .*$/ \/var\/run\/freshclam.pid/'                 /etc/freshclam.conf


# clamav-milter
# cp -p /usr/local/share/examples/clamav/clamav-milter.conf.sample  /etc/clamav-milter.conf
# diff /usr/local/share/examples/clamav/clamav-milter.conf.sample  /etc/clamav-milter.conf
sed -i '/^Example/s/^E/#E/'             /etc/clamav-milter.conf

sed -i '/MilterSocket \/tmp/s/^#//'     /etc/clamav-milter.conf
#User _postfix
sed -i '/PidFile/s/^#//'                /etc/clamav-milter.conf
sed -i '/^PidFile/s/ .*$/ \/var\/run\/clamav-milter.pid/' /etc/clamav-milter.conf

sed -i '/^#ClamdSocket/a\
ClamdSocket unix:/tmp/clamd.sock'       /etc/clamav-milter.conf

sed -i '/^#OnInfected/s/^#//'           /etc/clamav-milter.conf
sed -i '/^OnInfected/s/ .*$/ Reject/'   /etc/clamav-milter.conf
#RejectMsg Message Infected with "%v"

sed -i '/LogSyslog/s/^#//g'             /etc/clamav-milter.conf
sed -i '/LogFacility/s/^#//g'           /etc/clamav-milter.conf

sed -i '/^#LogInfected/s/^#//'          /etc/clamav-milter.conf
sed -i '/^LogInfected/s/ .*$/ Full/'    /etc/clamav-milter.conf




if [ ! -f /var/db/clamav/main.cld ]; then
  echo "Initial download of ClamAV AV Signatures"
  touch /var/log/freshclam.log && chown _clamav:_clamav /var/log/freshclam.log
  
  # Do initial download for clamav
  /usr/local/bin/freshclam --no-warnings
fi

rcctl enable freshclam
rcctl start  freshclam
rcctl enable clamav_milter
rcctl start  clamav_milter
rcctl enable clamd
rcctl start  clamd