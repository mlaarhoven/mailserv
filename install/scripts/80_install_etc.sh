#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

# --------------------------------------------------------------
# sasl and filesystem stuff
# --------------------------------------------------------------
install /var/mailserv/install/templates/fs/bin/* /usr/local/bin/
install /var/mailserv/install/templates/fs/sbin/* /usr/local/sbin/

mkdir -p /usr/local/share/mailserv
install /var/mailserv/install/templates/fs/mailserv/* /usr/local/share/mailserv

template="/var/mailserv/install/templates"
install -m 644 \
  ${template}/daily.local \
  ${template}/monthly.local \
  ${template}/login.conf \
  ${template}/profile \
  ${template}/rc.shutdown \
  ${template}/syslog.conf \
  /etc

cat ${template}/newsyslog.conf >> /etc/newsyslog.conf

install -m 600 ${template}/pf.conf /etc


install -m 644 /var/mailserv/install/templates/rc.local /etc

# --------------------------------------------------------------
# /etc/motd
# --------------------------------------------------------------
echo ""  > /etc/motd
echo "" >> /etc/motd
echo "Welcome to Mailserv" >> /etc/motd
cat /var/mailserv/VERSION >> /etc/motd
date >> /etc/motd
echo "" >> /etc/motd

# --------------------------------------------------------------
# Setup package daemons
# --------------------------------------------------------------
rcctl stop sndiod
rcctl disable sndiod

# --------------------------------------------------------------
# /etc/services
# --------------------------------------------------------------

if [ `grep mailadm /etc/services | wc -l` -eq 0 ]; then
cat <<EOF >> /etc/services
mailadm 4200/tcp # Mailserver admin port
EOF
fi


# --------------------------------------------------------------
# Symlinks for ruby stuff 
# --------------------------------------------------------------
pkg_add ruby
    #  ruby-gems \
    #  ruby-rake \
    #  ruby-iconv


  #ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
  #ln -sf /usr/local/bin/python2.7-2to3 /usr/local/bin/2to3
  #ln -sf /usr/local/bin/python2.7-config /usr/local/bin/python-config
  #ln -sf /usr/local/bin/pydoc2.7  /usr/local/bin/pydoc

  # set default system ruby	 
 ln -sf /usr/local/bin/ruby32 /usr/local/bin/ruby
 ln -sf /usr/local/bin/bundle32 /usr/local/bin/bundle
 ln -sf /usr/local/bin/bundler32 /usr/local/bin/bundler
 ln -sf /usr/local/bin/erb32 /usr/local/bin/erb
 ln -sf /usr/local/bin/gem32 /usr/local/bin/gem
 ln -sf /usr/local/bin/irb32 /usr/local/bin/irb
 ln -sf /usr/local/bin/racc32 /usr/local/bin/racc
 ln -sf /usr/local/bin/rake32 /usr/local/bin/rake
 ln -sf /usr/local/bin/rbs32 /usr/local/bin/rbs
 ln -sf /usr/local/bin/rdbg32 /usr/local/bin/rdbg
 ln -sf /usr/local/bin/rdoc32 /usr/local/bin/rdoc
 ln -sf /usr/local/bin/ri32 /usr/local/bin/ri
 ln -sf /usr/local/bin/syntax_suggest32 /usr/local/bin/syntax_suggest
 ln -sf /usr/local/bin/typeprof32 /usr/local/bin/typeprof

  # -----------------------------------------------------
  # Update your RAILS_GEM_VERSION
  # -----------------------------------------------------
  echo " Installing rails:"
  /usr/local/bin/gem install -V -v=2.3.4 rails
  echo " Installing rubby apps:"
  /usr/local/bin/gem install -V -v=1.6.21 highline
  /usr/local/bin/gem install -V resurrected_god rdoc fastercsv ruby-mysql #mongrel

  #ln -sf /usr/local/bin/mongrel_rails18 /usr/local/bin/mongrel_rails
  ln -sf /usr/local/bin/rails32 /usr/local/bin/rails 
  ln -sf /usr/local/bin/god32 /usr/local/bin/god


# --------------------------------------------------------------
# /etc/mail/aliases
# --------------------------------------------------------------

# either we're upgrading
/usr/local/bin/ruby -pi -e '$_.gsub!(/\/usr\/local\/share\/mailserver\/sysmail.rb/, "/usr/local/share/mailserv/sysmail.rb")' /etc/mail/aliases

# or do a fresh install
if [[ `grep sysmail.rb /etc/mail/aliases | wc -l` -eq 0 ]]; then
cat <<EOF >> /etc/mail/aliases
#
# Email system messages to the mailserv admins
#
root: |/usr/local/share/mailserv/sysmail.rb
EOF
fi
/usr/bin/newaliases >/dev/null 2>&1

# --------------------------------------------------------------
# /etc/sysctl.conf
# --------------------------------------------------------------
#/usr/local/bin/rake -s -f /var/mailserv/admin/Rakefile system:update_hostname RAILS_ENV=production

chgrp 0 /etc/daily.local \
        /etc/login.conf \
        /etc/monthly.local \
        /etc/pf.conf \
        /etc/rc.local \
        /etc/rc.shutdown \
        /etc/shells \
        /etc/syslog.conf

# --------------------------------------------------------------
# /etc/god
# --------------------------------------------------------------
mkdir /etc/god
install -m 644 /var/mailserv/install/templates/fs/god/* /etc/god


