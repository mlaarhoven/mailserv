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
## DOMAINS (use dovecot table mail.domains)
cat <<EOF > /etc/postfix/mysql-domains.cf
hosts = localhost
user = postfix
password = postfix
dbname = mail
query = SELECT name FROM domains WHERE name='%s'
EOF
postconf virtual_mailbox_domains=proxy:mysql:/etc/postfix/mysql-domains.cf

## MAILBOX (use dovecot table mail.users)
cat <<EOF > /etc/postfix/mysql-mailboxes.cf
hosts = localhost
user = postfix
password = postfix
dbname = mail
query = SELECT CONCAT(SUBSTRING_INDEX(email,'@',-1),'/',SUBSTRING_INDEX(email,'@',1),'/') FROM users WHERE email='%s'
EOF
postconf virtual_mailbox_maps=proxy:mysql:/etc/postfix/mysql-mailboxes.cf
postconf virtual_minimum_uid=2000

## ALIAS (create new table mail.forwardings)
echo "CREATE TABLE forwardings (
  id int(11) NOT NULL AUTO_INCREMENT,
  domain_id int(11) NOT NULL,
  source varchar(128) NOT NULL,
  destination text NOT NULL,
  created_at datetime DEFAULT NULL,
  updated_at datetime DEFAULT NULL,
  PRIMARY KEY (id)
)" | /usr/local/bin/mysql mail
/usr/local/bin/mysql mail -e "ALTER TABLE forwardings ADD FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE RESTRICT ON UPDATE RESTRICT;"
# new mysql user "postfix"
/usr/local/bin/mysql -e "CREATE USER 'postfix'@'localhost' identified by 'postfix'"
/usr/local/bin/mysql -e "GRANT SELECT ON mail.domains     TO 'postfix'@'localhost'"
/usr/local/bin/mysql -e "GRANT SELECT ON mail.users       TO 'postfix'@'localhost'"
/usr/local/bin/mysql -e "GRANT SELECT ON mail.forwardings TO 'postfix'@'localhost'"
/usr/local/bin/mysql -e "FLUSH PRIVILEGES"

cat <<EOF > /etc/postfix/mysql-forwardings.cf
hosts = localhost
user = postfix
password = postfix
dbname = mail
query = SELECT destination FROM forwardings WHERE source='%s'
EOF
cat <<EOF > /etc/postfix/mysql-email2email.cf
hosts = localhost
user = postfix
password = postfix
dbname = mail
query = SELECT email FROM users WHERE email='%s'
EOF
postconf virtual_alias_domains=
postconf virtual_alias_maps=proxy:mysql:/etc/postfix/mysql-forwardings.cf,proxy:mysql:/etc/postfix/mysql-email2email.cf


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
# no authentication on port 25 allowed. Should use submission(s), port 587 or 465
postconf smtpd_sasl_auth_enable=no
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
# Requiring that the client sends the HELO or EHLO command
postconf smtpd_helo_required=yes
# RFC 821 Compliance
postconf strict_rfc821_envelopes=yes


# https://www.postfix.org/SMTPD_ACCESS_README.html#lists
## CLIENT
# Reject the request when the client IP address has no hostname
postconf "smtpd_client_restrictions= \
  reject_unknown_reverse_client_hostname \
  reject_rbl_client zen.spamhaus.org \
  reject_rbl_client bl.spamcop.net \
  reject_rhsbl_reverse_client dbl.spamhaus.org"
#   check_policy_service inet:127.0.0.1:2501      =>sqlgrey

## HELO
#reject_invalid_helo_hostname  # Reject the request when the HELO or EHLO hostname is malformed.
#reject_non_fqdn_helo_hostname # Reject the request when the HELO or EHLO hostname is not in fully-qualified domain or address literal form, as required by the RFC.
#reject_unknown_helo_hostname  # Reject the request when the HELO or EHLO hostname has no DNS A or MX record.
postconf "smtpd_helo_restrictions= \
  reject_rhsbl_helo dbl.spamhaus.org"

## SENDER
# Don't accept mail from domains that don't exist.
# Reject the request when the MAIL FROM address specifies a domain that is not in fully-qualified domain form
postconf "smtpd_sender_restrictions= \
  reject_unknown_sender_domain \
  reject_non_fqdn_sender \
  reject_rhsbl_sender dbl.spamhaus.org"

## RECIPIENT
# Reject the request when recipient domain has no DNS MX
# Reject the request when the RCPT TO address specifies a domain that is not in fully-qualified domain form
# Permit mynetworks or authenticated users
# Reject using rbl & rhsbl
postconf "smtpd_recipient_restrictions= \
  reject_unknown_recipient_domain \
  reject_non_fqdn_recipient"

## RELAY
postconf "smtpd_relay_restrictions= \
  permit_mynetworks \
  permit_sasl_authenticated \
  reject_unauth_destination"

## DATA
# Block clients that speak too early.
postconf "smtpd_data_restrictions= \
  reject_unauth_pipelining"

## END OF DATA




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
postconf smtp_tls_security_level=dane
postconf smtp_dns_support_level=dnssec
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

# prevent SMTP Smuggling
# https://www.postfix.org/smtp-smuggling.html
#postconf smtpd_forbid_bare_newline=normalize
# for postfix 3.7.9
postconf smtpd_forbid_bare_newline=yes


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



### master.cf
# use example config
# cp /usr/local/share/examples/postfix/master.cf /etc/postfix/master.cf
# diff /usr/local/share/examples/postfix/master.cf /etc/postfix/master.cf

# submission 587/tcp mail message submission
postconf -M submission/inet="submission inet n - y - - smtpd"
postconf -P submission/inet/syslog_name=postfix\/submission
postconf -P submission/inet/smtpd_tls_security_level=encrypt
postconf -P submission/inet/smtpd_sasl_auth_enable=yes
postconf -P submission/inet/smtpd_tls_auth_only=yes
postconf -P submission/inet/smtpd_reject_unlisted_recipient=no
postconf -P submission/inet/smtpd_client_restrictions=
postconf -P submission/inet/smtpd_helo_restrictions=
postconf -P submission/inet/smtpd_sender_restrictions=
postconf -P submission/inet/smtpd_relay_restrictions=
postconf -P submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING

# TODO clamav
# -o smtpd_milters=unix:/tmp/clamav-milter.sock


#remove postconf -MX submissions/inet 
# submissions 465/tcp mail message submission (TLS)
postconf -M submissions/inet="submissions inet n - y - - smtpd"
postconf -P submissions/inet/syslog_name=postfix\/submissions
postconf -P submissions/inet/smtpd_tls_wrappermode=yes
postconf -P submissions/inet/smtpd_sasl_auth_enable=yes
postconf -P submissions/inet/smtpd_reject_unlisted_recipient=no
postconf -P submissions/inet/smtpd_client_restrictions=
postconf -P submissions/inet/smtpd_helo_restrictions=
postconf -P submissions/inet/smtpd_sender_restrictions=
postconf -P submissions/inet/smtpd_relay_restrictions=
postconf -P submissions/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject
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
#install ${template}/sql/routing.cf      /etc/postfix/sql/


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