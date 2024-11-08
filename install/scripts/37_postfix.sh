#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I postfix-3.7.9p0-mysql
#pkg_add -v -m -I postfix-3.8.20221007p12-mysql

# info
# /usr/local/share/doc/postfix/html/index.html

# use example settings
# cp -r /usr/local/share/examples/postfix/* /etc/postfix/
# diff -r /usr/local/share/examples/postfix /etc/postfix/

template="/var/mailserv/install/templates/postfix"
### main.cf

# The default setting is 550 (reject mail) but it is safer to initially use 450 (try again later) so you have time to find out if your local_recipient_maps settings are OK.
postconf unknown_local_recipient_reject_code=450
# use + or - as recipient_delimiter for detail mailboxes
postconf recipient_delimiter=+-


# Virtual mailbox settings
# https://www.postfix.org/VIRTUAL_README.html#in_virtual_other
postconf virtual_transport=lmtp:unix:private/dovecot-lmtp

# https://www.postfix.org/mysql_table.5.html
# TODO stored procedures?
cat <<EOF > /etc/postfix/mysql-domains.cf
hosts = localhost
user = postfix
password = postfix
dbname = mail
query = SELECT name FROM domains WHERE name='%s'
EOF
postconf virtual_mailbox_domains=proxy:mysql:/etc/postfix/mysql-domains.cf

cat <<EOF > /etc/postfix/mysql-mailboxes.cf
hosts = localhost
user = postfix
password = postfix
dbname = mail
query = SELECT CONCAT(SUBSTRING_INDEX(email,'@',-1),'/',SUBSTRING_INDEX(email,'@',1),'/') FROM users WHERE email='%s'
EOF
postconf virtual_mailbox_maps=proxy:mysql:/etc/postfix/mysql-mailboxes.cf
postconf virtual_minimum_uid=2000
#postconf virtual_uid_maps=proxy:mysql:/etc/postfix/sql/user.cf
#postconf virtual_gid_maps=proxy:mysql:/etc/postfix/sql/group.cf
#forwarding
#postconf virtual_alias_domains = 
#postconf virtual_alias_maps         = proxy:mysql:/etc/postfix/sql/forwardings.cf 
#                                      proxy:mysql:/etc/postfix/sql/email2email.cf


# Add LMTP socket to dovecot
# https://doc.dovecot.org/configuration_manual/protocols/lmtp_server/
# https://doc.dovecot.org/configuration_manual/howto/postfix_dovecot_lmtp/
sed -i '/unix_listener lmtp/i\
  unix_listener /var/spool/postfix/private/dovecot-lmtp {\
    mode = 0600\
    user = _postfix\
    group = _postfix\
  }\
'                                       /etc/dovecot/conf.d/10-master.conf
#remove sample
sed -i '/unix_listener lmtp/,/}/d'      /etc/dovecot/conf.d/10-master.conf



# Authentication settings
# https://www.postfix.org/SASL_README.html#server_sasl_enable
# https://doc.dovecot.org/configuration_manual/howto/postfix_and_dovecot_sasl/
postconf smtpd_sasl_type=dovecot
postconf smtpd_sasl_path=private/auth
postconf smtpd_sasl_auth_enable=yes
postconf broken_sasl_auth_clients=yes

# Add SASL socket to dovecot
# https://www.postfix.org/SASL_README.html
# https://www.postfix.org/SASL_README.html#server_dovecot
# Postfix smtp-auth
sed -i '/private\/auth/,/}/d'                                                /etc/dovecot/conf.d/10-master.conf
sed -i '/# Postfix smtp-auth/i\
  unix_listener /var/spool/postfix/private/auth {\
    mode = 0660\
    user = _postfix\
    group = _postfix\
  }\
'                                                                           /etc/dovecot/conf.d/10-master.conf


# SMTP Requirements
# https://www.postfix.org/SMTPD_ACCESS_README.html
# https://www.postfix.org/SMTPD_POLICY_README.html
# https://www.postfix.org/ADDRESS_VERIFICATION_README.html

# https://www.postfix.org/SMTPD_ACCESS_README.html#global
postconf smtpd_helo_required=yes
# RFC 821 Compliance https://www.postfix.org/postconf.5.html#strict_rfc821_envelopes
postconf strict_rfc821_envelopes=yes


# Reject the request when the client IP address has no hostname
postconf smtpd_client_restrictions=reject_unknown_reverse_client_hostname
#   check_policy_service inet:127.0.0.1:2501      =>sqlgrey

# Don't accept mail from domains that don't exist.
# Reject the request when the MAIL FROM address specifies a domain that is not in fully-qualified domain form
postconf smtpd_sender_restrictions=reject_unknown_sender_domain,reject_non_fqdn_sender

# Reject the request when recipient domain has no DNS MX
# Reject the request when the RCPT TO address specifies a domain that is not in fully-qualified domain form
# Permit mynetworks or authenticated users
# Reject using rbl & rhsbl
postconf "smtpd_recipient_restrictions= \
  reject_unknown_recipient_domain \
  reject_non_fqdn_recipient \
  permit_mynetworks \
  permit_sasl_authenticated \
  reject_rbl_client zen.spamhaus.org \
  reject_rbl_client bl.spamcop.net \
  reject_rhsbl_reverse_client dbl.spamhaus.org \
  reject_rhsbl_helo dbl.spamhaus.org \
  reject_rhsbl_sender dbl.spamhaus.org"

postconf smtpd_relay_restrictions=permit_mynetworks,permit_sasl_authenticated,reject_unauth_destination

# Block clients that speak too early.
postconf smtpd_data_restrictions=reject_unauth_pipelining






# TLS Settings
# https://www.postfix.org/TLS_README.html

# SMTP server
# smtp 25/tcp mail
postconf smtpd_tls_security_level=may
postconf smtpd_tls_chain_files=/etc/ssl/private/server.key,/etc/ssl/server.crt
postconf smtpd_tls_auth_only=yes
postconf smtpd_tls_loglevel=1
postconf smtpd_tls_received_header=yes

# SMTP client
#TODO dane?
  #smtp_tls_security_level=dane
  #smtp_dns_support_level=dnssec
  #When using Postfix DANE support the "smtp_host_lookup" parameter should include "dns"
postconf smtp_tls_security_level=may
postconf smtp_tls_loglevel=1
postconf smtp_tls_note_starttls_offer=yes
#postconf smtp_tls_chain_files=/etc/ssl/private/server.key,/etc/ssl/server.crt
postconf smtp_tls_session_cache_database=btree:/var/postfix/smtp_tls_session_cache
#use root certs to check remote servers
postconf smtp_tls_CAfile=/etc/ssl/cert.pem

#generate tlsa record
#postfix tls output-server-tlsa /etc/ssl/private/server.key



# to allow messages of approximately 20 MB, perform the following calculation:
#  20971520 bytes * 4/3 for Base64 encoding = 27962027 (rounded up)
postconf message_size_limit=27962027

# Milter settings
# TODO

# OLD 5.9
# milter_default_action = tempfail
# milter_connect_macros = j {daemon_name} v _
# milter_header_checks = pcre:/etc/postfix/milter_header_checks
# header_checks = pcre:/etc/postfix/header_checks.pcre
# smtpd_milters =
#   unix:/tmp/clamav-milter.sock


# OLD 5.9
# spamassassin_destination_recipient_limit = 1
# transport_maps = proxy:mysql:/etc/postfix/sql/routing.cf
# relay_domains = proxy:mysql:/etc/postfix/sql/routing.cf


# OLD 5.9
# proxy_read_maps =
#     proxy:mysql:/etc/postfix/sql/routing.cf
#     proxy:mysql:/etc/postfix/sql/domains.cf
#     proxy:mysql:/etc/postfix/sql/mailboxes.cf
#     proxy:mysql:/etc/postfix/sql/user.cf
#     proxy:mysql:/etc/postfix/sql/group.cf
#     proxy:mysql:/etc/postfix/sql/forwardings.cf
#     proxy:mysql:/etc/postfix/sql/email2email.cf
#     proxy:unix:passwd.byname
#     unix:passwd.byname


#TODO SMTP smuggling?
# https://www.postfix.org/smtp-smuggling.html


### master.cf
# use example config
# cp /usr/local/share/examples/postfix/master.cf /etc/postfix/master.cf
# diff /usr/local/share/examples/postfix/master.cf /etc/postfix/master.cf

# submission 587/tcp mail message submission
postconf -M submission/inet="submission inet n - y - - smtpd"
postconf -P submission/inet/syslog_name=postfix\/submission
postconf -P submission/inet/smtpd_tls_security_level=encrypt
postconf -P submission/inet/smtpd_sasl_auth_enable=yes
#  -o smtpd_tls_auth_only=yes
#  -o smtpd_reject_unlisted_recipient=no
#     Instead of specifying complex smtpd_<xxx>_restrictions here,
#     specify "smtpd_<xxx>_restrictions=$mua_<xxx>_restrictions"
#     here, and specify mua_<xxx>_restrictions in main.cf (where
#     "<xxx>" is "client", "helo", "sender", "relay", or "recipient").
#  -o smtpd_client_restrictions=
#  -o smtpd_helo_restrictions=
#  -o smtpd_sender_restrictions=
#  -o smtpd_relay_restrictions=
#  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING

# TODO clamav
# -o smtpd_milters=unix:/tmp/clamav-milter.sock


#remove postconf -MX submissions/inet 
# submissions 465/tcp mail message submission (TLS)
postconf -M submissions/inet="submissions inet n - y - - smtpd"
postconf -P submissions/inet/syslog_name=postfix\/submissions
postconf -P submissions/inet/smtpd_tls_wrappermode=yes
postconf -P submissions/inet/smtpd_sasl_auth_enable=yes
#  -o smtpd_reject_unlisted_recipient=no
#     Instead of specifying complex smtpd_<xxx>_restrictions here,
#     specify "smtpd_<xxx>_restrictions=$mua_<xxx>_restrictions"
#     here, and specify mua_<xxx>_restrictions in main.cf (where
#     "<xxx>" is "client", "helo", "sender", "relay", or "recipient").
#  -o smtpd_client_restrictions=
#  -o smtpd_helo_restrictions=
#  -o smtpd_sender_restrictions=
#  -o smtpd_relay_restrictions=
#  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING

# TODO clamav
# -o smtpd_milters=unix:/tmp/clamav-milter.sock


install -m 644 ${template}/header_checks.pcre /etc/postfix
install -m 644 ${template}/milter_header_checks /etc/postfix

#
# Make sure the /etc/postfix/sql directory exists and is executable
#
#mkdir -p /etc/postfix/sql
#chmod 755 /etc/postfix/sql

#
# Install the /etc/postfix/sql files
#
#install ${template}/sql/email2email.cf  /etc/postfix/sql/
#install ${template}/sql/forwardings.cf  /etc/postfix/sql/
#install ${template}/sql/group.cf        /etc/postfix/sql/
#install ${template}/sql/routing.cf      /etc/postfix/sql/
#install ${template}/sql/user.cf         /etc/postfix/sql/

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