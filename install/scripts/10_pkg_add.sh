#!/bin/sh

if [ ! -f /etc/installurl ]; then
    echo "Install URL"
    echo 'https://ftp.openbsd.org/pub/OpenBSD/' > /etc/installurl
fi

case $1 in

    (install):
        echo "Installing packages"
        mkdir -p /var/db/spamassassin

        cat <<__EOT
    

Fetching versions:

__EOT

        pkg_add -v -m -I \
            gnupg \
            ruby-3.0.5 \
            gsed \
            gtar--static \
            ghostscript-fonts \
            ghostscript--no_x11 \
            ImageMagick \
            lynx \
            vim--no_x11 \
            sudo--
            ;;
#            dnsmasq \

esac
