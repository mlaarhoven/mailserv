#!/bin/sh

if [ ! -f /etc/installurl ]; then
    echo "Install URL"
    echo 'https://ftp.openbsd.org/pub/OpenBSD/' > /etc/installurl
fi

case $1 in

    (install):
        echo "Installing packages"

        cat <<__EOT
    

Fetching versions:

__EOT

        pkg_add -v -m -I \
            gnupg \
            gsed \
            gtar--static \
            ghostscript-fonts \
            ghostscript--no_x11 \
            ImageMagick \
            lynx \
            vim--no_x11 \
            sudo--
            ;;

esac
