#!/bin/sh

# Only run on install
[[ "$1" != "install" ]] && exit 1

pkg_add -v -m -I \
    dovecot \
    dovecot-pigeonhole \
    dovecot-mysql

# info
# /usr/local/share/doc/pkg-readmes/dovecot
# /etc/login.conf.d/dovecot
# /usr/local/share/doc/dovecot/wiki/Quota.txt


# use example config
# cp -rp /usr/local/share/examples/dovecot/example-config/* /etc/dovecot/
# diff -r /usr/local/share/examples/dovecot/example-config/ /etc/dovecot/

### conf.d/10-auth.conf
# use auth-sql
sed -i '/auth-system.conf.ext/s/^!/#!/'                                     /etc/dovecot/conf.d/10-auth.conf
sed -i '/auth-sql.conf.ext/s/^#//'                                          /etc/dovecot/conf.d/10-auth.conf


### /etc/dovecot/dovecot-sql.conf.ext
# Mysql settings
sed -i '/^#driver/s/^#//'                                                   /etc/dovecot/dovecot-sql.conf.ext
sed -i '/^driver =/s/=.*$/= mysql/'                                         /etc/dovecot/dovecot-sql.conf.ext
# TODO new dovecot user?
sed -i '/^#connect/s/^#//'                                                  /etc/dovecot/dovecot-sql.conf.ext
sed -i '/^connect =/s/=.*$/= host=127.0.0.1 dbname=mail user=dovecot password=dovecot/' /etc/dovecot/dovecot-sql.conf.ext

# TODO not use PLAIN?
sed -i '/^#default_pass_scheme/s/^#//'                                      /etc/dovecot/dovecot-sql.conf.ext
sed -i '/^default_pass_scheme =/s/=.*$/= PLAIN/'                            /etc/dovecot/dovecot-sql.conf.ext

# add password_query
# find first password_query and add marker
sed -i '1,/#password_query/s/#password_query/XXX/'                          /etc/dovecot/dovecot-sql.conf.ext
# add new password_query before marker
sed -i '/XXX/i\
password_query = SELECT email as user, password FROM users WHERE email = '"'"'%u'"'"'\
\
'                                                                           /etc/dovecot/dovecot-sql.conf.ext
# remove sample+marker
sed -i '/XXX/,/^$/d'                                                        /etc/dovecot/dovecot-sql.conf.ext

# add user_query
sed -i '/^#user_query/i\
user_query = SELECT id as uid, id as gid, home, concat('"'"'*:storage='"'"', quota, '"'"'M'"'"') AS quota_rule FROM users WHERE email = '"'"'%u'"'"'\
\
'                                                                           /etc/dovecot/dovecot-sql.conf.ext
# remove sample
sed -i '/^#user_query/,/^$/d'                                               /etc/dovecot/dovecot-sql.conf.ext

# add iterate_query
sed -i '/^#iterate_query/s/^#//'                                            /etc/dovecot/dovecot-sql.conf.ext
sed -i '/^iterate_query =/s/=.*$/= SELECT email AS user FROM users/'         /etc/dovecot/dovecot-sql.conf.ext


### conf.d/10-auth.conf
# Enables the PLAIN and LOGIN authentication mechanisms. The LOGIN mechanism is obsolete, but still used by old Outlooks and some Microsoft phones.
sed -i '/auth_mechanisms/s/=.*$/= plain login/'                             /etc/dovecot/conf.d/10-auth.conf


#### conf.d/10-mail.conf
# Set the location of the mailboxes
sed -i '/^#mail_location/s/^#//'                                            /etc/dovecot/conf.d/10-mail.conf
sed -i '/^mail_location/s/=.*$/= maildir:\/var\/mailserv\/mail\/%d\/%n/'    /etc/dovecot/conf.d/10-mail.conf
# Use quota plugin
sed -i '/^#mail_plugins/s/^#//'                                             /etc/dovecot/conf.d/10-mail.conf
sed -i '/^mail_plugins/s/=.*$/= quota/'                                     /etc/dovecot/conf.d/10-mail.conf
# Valid UID range for users
sed -i '/^first_valid_uid/s/=.*$/= 2000/'                                   /etc/dovecot/conf.d/10-mail.conf


### conf.d/10-master.conf
# Use less memory
sed -i '/^#default_vsz_limit/s/^#//'                                        /etc/dovecot/conf.d/10-master.conf
sed -i '/^default_vsz_limit/s/=.*$/= 64M/'                                  /etc/dovecot/conf.d/10-master.conf


### conf.d/10-ssl.conf
# Use our certificate+key
sed -i '/ssl_cert =/s/=.*$/= <\/etc\/ssl\/server.crt/'                      /etc/dovecot/conf.d/10-ssl.conf
sed -i '/ssl_key =/s/=.*$/= <\/etc\/ssl\/private\/server.key/'              /etc/dovecot/conf.d/10-ssl.conf


### conf.d/15-mailboxes.conf
# Junk -> Spam
sed -i '/mailbox Junk/s/Junk/Spam/'                                         /etc/dovecot/conf.d/15-mailboxes.conf
# Add Archives
sed -i '/mailbox Spam {/i\
  mailbox Archives {\
    special_use = \\Archive\
  }
'                                                                           /etc/dovecot/conf.d/15-mailboxes.conf
# Only "Sent"
sed -i '/mailbox "Sent Messages"/,/}/d'                                     /etc/dovecot/conf.d/15-mailboxes.conf
# auto = subscribe
sed -i '/^[[:blank:]]*special_use =/i\
    auto = subscribe
'                                                                           /etc/dovecot/conf.d/15-mailboxes.conf


### conf.d/15-lda.conf
# use + or - as recipient_delimiter for detail mailboxes
sed -i '/^#recipient_delimiter/s/^#//'                                      /etc/dovecot/conf.d/15-lda.conf
sed -i '/^recipient_delimiter/s/=.*$/= +-/'                                 /etc/dovecot/conf.d/15-lda.conf


### conf.d/20-lmtp.conf
# try to save the mail to the detail mailbox
sed -i '/^#lmtp_save_to_detail_mailbox/s/^#//'                              /etc/dovecot/conf.d/20-lmtp.conf
sed -i '/^lmtp_save_to_detail_mailbox/s/=.*$/= yes/'                        /etc/dovecot/conf.d/20-lmtp.conf

# Verify quota before replying to RCPT TO.
sed -i '/^#lmtp_rcpt_check_quota/s/^#//'                                    /etc/dovecot/conf.d/20-lmtp.conf
sed -i '/^lmtp_rcpt_check_quota/s/=.*$/= yes/'                              /etc/dovecot/conf.d/20-lmtp.conf


### conf.d/20-imap.conf
sed -i '/imap_client_workarounds/s/^#//'                                    /etc/dovecot/conf.d/20-imap.conf
sed -i '/imap_client_workarounds/s/=.*$/= delay-newmail/'                   /etc/dovecot/conf.d/20-imap.conf
# Add plugin imap_quota
sed -i '/mail_plugins/s/#mail_plugins/mail_plugins/'                        /etc/dovecot/conf.d/20-imap.conf
sed -i '/mail_plugins/s/=.*$/= $mail_plugins imap_quota/'                   /etc/dovecot/conf.d/20-imap.conf


### conf.d/20-pop3.conf
#  POP3 UIDL (unique mail identifier) format to use
# TODO use default? (default = %08Xu%08Xv)
sed -i '/^#pop3_uidl_format/s/^#//'                                         /etc/dovecot/conf.d/20-pop3.conf
sed -i '/pop3_uidl_format =/s/=.*$/= %08Xv%08Xu/'                           /etc/dovecot/conf.d/20-pop3.conf
# Workarounds for various client bugs
sed -i '/^#pop3_client_workarounds/s/^#//'                                  /etc/dovecot/conf.d/20-pop3.conf
sed -i '/pop3_client_workarounds =/s/=.*$/= outlook-no-nuls oe-ns-eoh/'     /etc/dovecot/conf.d/20-pop3.conf


# remove sieve_deprecated
sed -i '/inet_listener sieve_deprecated/,/}/d'                              /etc/dovecot/conf.d/20-managesieve.conf


### conf.d/90-quota.conf
# https://doc.dovecot.org/configuration_manual/quota_plugin/ 
# General quota limits
sed -i '1,/#quota_rule/s/#quota_rule/quota_rule/'                           /etc/dovecot/conf.d/90-quota.conf 
sed -i '1,/#quota_rule2/s/#quota_rule2/quota_rule2/'                        /etc/dovecot/conf.d/90-quota.conf 
#TODO?
#quota_rule3 = SPAM:ignore
# Send quota warning
#TODO use service quota-warning?
sed -i '/#quota_warning/s/#//'                                              /etc/dovecot/conf.d/90-quota.conf 
# Quota backend
sed -i '/#quota = maildir/s/#//'                                            /etc/dovecot/conf.d/90-quota.conf 


## TODO dovecot.conf

#protocol lda {
#  mail_plugins = $mail_plugins sieve
#}
# deprecated, replace with IMAPSieve 
# https://wiki2.dovecot.org/Plugins/Antispam
# https://doc.dovecot.org/configuration_manual/howto/antispam_with_sieve/
#plugin {
#  antispam_mail_notspam = --ham
#  antispam_mail_sendmail = /usr/local/bin/sa-learn
#   antispam_mail_sendmail_args = --username=%u
#   antispam_mail_spam = --spam
#   antispam_mail_tmpdir = /tmp
#   antispam_signature = X-Spam-Flag
#   antispam_signature_missing = move
#   antispam_spam = SPAM;Spam;spam;Junk;junk
#   antispam_trash = trash;Trash;Deleted Items;Deleted Messages
# }




/usr/local/bin/mysqladmin create mail

# Create tables
echo "CREATE TABLE domains ( \
    id int(11) NOT NULL AUTO_INCREMENT, \
    name varchar(128) DEFAULT NULL, \
    created_at datetime DEFAULT NULL, \
    updated_at datetime DEFAULT NULL, \
    quota int(11) DEFAULT NULL, \
    quotamax int(11) DEFAULT NULL, \
PRIMARY KEY (id), \
UNIQUE KEY domain_uniq (name) \
)" | /usr/local/bin/mysql mail


echo "CREATE TABLE users (
    id int(11) NOT NULL AUTO_INCREMENT,
    domain_id int(11) DEFAULT NULL,
    email varchar(128) NOT NULL DEFAULT '',
    name varchar(128) DEFAULT NULL,
    fullname varchar(128) DEFAULT NULL,
    password varchar(128) NOT NULL DEFAULT '',
    home varchar(255) NOT NULL DEFAULT '',
#priority int(11) NOT NULL DEFAULT '7',
#policy_id int(10) unsigned NOT NULL DEFAULT '1',
    created_at datetime DEFAULT NULL,
    updated_at datetime DEFAULT NULL,
    quota int(11) DEFAULT NULL,
PRIMARY KEY (id),
UNIQUE KEY email_uniq (email)
) AUTO_INCREMENT=2000" | /usr/local/bin/mysql mail

/usr/local/bin/mysql mail -e "ALTER TABLE users ADD FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE RESTRICT ON UPDATE RESTRICT;"

/usr/local/bin/mysql -e "CREATE USER 'dovecot'@'localhost' identified by 'dovecot'"
/usr/local/bin/mysql -e "GRANT SELECT ON mail.domains TO 'dovecot'@'localhost'"
/usr/local/bin/mysql -e "GRANT SELECT ON mail.users   TO 'dovecot'@'localhost'"
/usr/local/bin/mysql -e "FLUSH PRIVILEGES"


#
# Making dovecot-lda deliver setuid root
# (needed for delivery to different userids)
#
#touch /var/log/imap
#https://doc.dovecot.org/configuration_manual/protocols/lda/
#chgrp _dovecot /usr/local/libexec/dovecot/dovecot-lda
#chmod 4750 /usr/local/libexec/dovecot/dovecot-lda
mkdir -p /var/mailserv/mail

#---------------------------------------------------------------
#  increase openfiles limit to 1024 ( obsd usualy runs 128 )
#  necessary to dovecot start up
#  (when server reboot limits are read from login.conf, sysctl.conf) 
#---------------------------------------------------------------
#Now in /etc/login.conf.d/dovecot
# maxfilestest=$( ulimit -n )
# 
# if [ $maxfilestest -lt 1024 ];
#   then
#     echo " "
#     echo " setting openfiles-max to 1024 "
#     echo " "
#     ulimit -n 1024
# fi

rcctl enable dovecot
rcctl start dovecot
