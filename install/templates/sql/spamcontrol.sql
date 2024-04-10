GRANT SELECT ON spamcontrol.* TO 'spamassassin'@'localhost' identified BY 'spamassassin';
GRANT SELECT, UPDATE, DELETE, INSERT ON spamcontrol.bayes_token  TO 'spamassassin'@'localhost';
GRANT SELECT, UPDATE, DELETE, INSERT ON spamcontrol.bayes_vars   TO 'spamassassin'@'localhost';
GRANT SELECT, DELETE, INSERT         ON spamcontrol.bayes_seen   TO 'spamassassin'@'localhost';
GRANT SELECT, DELETE, INSERT         ON spamcontrol.bayes_expire TO 'spamassassin'@'localhost';
GRANT SELECT, UPDATE, DELETE, INSERT ON spamcontrol.awl          TO 'spamassassin'@'localhost';