#!/bin/bash

USER="da_admin"
PASSWORD="`grep passwd= /usr/local/directadmin/conf/mysql.conf | cut -d\= -f2`"
BACKUP_RETAIN_DAYS=1   ## Number of days to keep local backup copy
DB_BACKUP_PATH='/home/mysqlbackups'
TODAY=`date +"%Y%m%d"`

#OUTPUT="/Users/rabino/DBs"

find ${DB_BACKUP_PATH} -name '*.gz' -type f -mtime +${BACKUP_RETAIN_DAYS} -exec rm -f {} \;

databases=`mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
        echo "Dumping database: $db"
        mysqldump -u $USER -p$PASSWORD --databases $db | gzip > ${TODAY}.$db.sql.gz
       # gzip $OUTPUT/`date +%Y%m%d`.$db.sql
    fi
done
