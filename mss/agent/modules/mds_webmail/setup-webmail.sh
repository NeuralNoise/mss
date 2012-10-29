#!/bin/bash
# Copyright Mandriva 2009, 2010 all rights reserved

. '../functions.sh'

check_root

roundcube_db_conf_template="templates/db.inc.php.tpl"
roundcube_main_conf_template="templates/main.inc.php.tpl"

# copy the db config
backup /etc/roundcubemail/db.inc.php
cat $roundcube_db_conf_template > /etc/roundcubemail/db.inc.php

# setup the roundcube db
if [ -f /var/lib/roundcubemail/sqlite.db ]; then
    rm -f /var/lib/roundcubemail/sqlite.db
fi
mkdir -p /var/lib/roundcubemail
chown apache /var/lib/roundcubemail
sqlite /var/lib/roundcubemail/sqlite.db < /usr/share/roundcubemail/SQL/sqlite.initial.sql
chown apache:apache /var/lib/roundcubemail/sqlite.db
chmod 0600 /var/lib/roundcubemail/sqlite.db

# set correct permissions
chown -R apache.apache /usr/share/roundcubemail/
chown -R apache.apache /var/log/roundcubemail/

# http -> https redirection
https_redirect roundcubemail /etc/httpd/conf/webapps.d/roundcubemail.conf

restart_service httpd

# copy main config
backup /etc/roundcubemail/main.inc.php
cat $roundcube_main_conf_template > /etc/roundcubemail/main.inc.php

echo "8Webmail Roundcube is activated on your server."
echo "8You can access the webmail interface at https://@HOSTNAME@/roundcubemail/"
