#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1


#----------------------------------------------------------------
# increase kern.maxfiles (important for dovecot)
#----------------------------------------------------------------

kernmaxfiles=$( sysctl -n kern.maxfiles )
kernmaxnew=10000

if [ $kernmaxfiles -lt $kernmaxnew ];
  then
   echo " "
   echo " setting kernmaxfiles "
   echo "kern.maxfiles=$kernmaxnew" >> /etc/sysctl.conf
fi
