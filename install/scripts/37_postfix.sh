#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

#pkg_add -v -m -I postfix-3.7.3p8-mysql
pkg_add -v -m -I postfix-3.8.20221007p8-mysql

# info
# /usr/local/share/doc/postfix/html/index.html

# use example settings
# cp -r /usr/local/share/examples/postfix /etc/postfix/
# diff -r /usr/local/share/examples/postfix /etc/postfix/

template="/var/mailserv/install/templates/postfix"
install -m 644 ${template}/main.cf /etc/postfix
### main.cf

# The default setting is 550 (reject mail) but it is safer to initially use 450 (try again later) so you have time to find out if your local_recipient_maps settings are OK.
postconf unknown_local_recipient_reject_code=450


# Virtual mailbox settings
# TODO


# RFC 821 Compliance https://www.postfix.org/postconf.5.html#strict_rfc821_envelopes
postconf strict_rfc821_envelopes=yes

# Authentication settings
# https://doc.dovecot.org/configuration_manual/howto/postfix_and_dovecot_sasl/
postconf smtpd_sasl_type=dovecot
postconf smtpd_sasl_path=private/auth
postconf smtpd_sasl_auth_enable=yes
#smtpd_sasl_security_options = noanonymous
#smtpd_sasl_local_domain =

postconf broken_sasl_auth_clients=yes

# SMTP Requirements
# TODO


# TLS Settings
postconf smtpd_tls_security_level=may
postconf smtpd_tls_auth_only=yes
postconf smtpd_tls_cert_file=/etc/ssl/server.crt
postconf smtpd_tls_key_file=/etc/ssl/private/server.key
postconf smtpd_tls_received_header=yes

postconf smtp_tls_security_level=may
#https://www.postfix.org/postconf.5.html#smtp_tls_cert_file
#postconf smtp_tls_cert_file=/etc/ssl/server.crt
#postconf smtp_tls_key_file=/etc/ssl/private/server.key


#postconf smtpd_tls_cert_file = /etc/letsencrypt/live/<your.domain>/fullchain.pem
#postconf smtpd_tls_key_file =  /etc/letsencrypt/live/<your.domain>/privkey.pem
#sudo postconf smtp_tls_note_starttls_offer = yes
#sudo postconf smtpd_tls_loglevel = 1



# to allow messages of approximately 20 MB, perform the following calculation:
#  20971520 bytes * 4/3 for Base64 encoding = 27962027 (rounded up)
postconf message_size_limit=27962027

# Milter settings
# TODO







install -m 644 ${template}/master.cf /etc/postfix
install -m 644 ${template}/header_checks.pcre /etc/postfix
install -m 644 ${template}/milter_header_checks /etc/postfix

#
# Make sure the /etc/postfix/sql directory exists and is executable
#
mkdir -p /etc/postfix/sql
chmod 755 /etc/postfix/sql

#
# Install the /etc/postfix/sql files
#
install ${template}/sql/domains.cf      /etc/postfix/sql/
install ${template}/sql/email2email.cf  /etc/postfix/sql/
install ${template}/sql/forwardings.cf  /etc/postfix/sql/
install ${template}/sql/group.cf        /etc/postfix/sql/
install ${template}/sql/mailboxes.cf    /etc/postfix/sql/
install ${template}/sql/routing.cf      /etc/postfix/sql/
install ${template}/sql/user.cf         /etc/postfix/sql/

# Make sure that the mailer is being set
if [[ `grep "/usr/sbin/smtpctl" /etc/mailer.conf | wc -l` -gt 0 ]]; then
    /usr/local/sbin/postfix-enable > /dev/null 2>&1

    #stop smtpd from base
    rcctl stop smtpd
    rcctl disable smtpd

    #start postfix
    rcctl enable postfix
    rcctl start postfix
fi