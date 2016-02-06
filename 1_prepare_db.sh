#!/bin/bash
source 0_common.sh
MYSQL="mysql -uroot -p$DB_PASS -h$DB_HOST -P$DB_PORT"
for SERVICE in keystone glance neutron cinder nova ceilometer; do
    $MYSQL -e "DROP DATABASE IF EXISTS $SERVICE"
    $MYSQL -e "CREATE DATABASE IF NOT EXISTS $SERVICE"
    $MYSQL -e "GRANT ALL PRIVILEGES ON ${SERVICE}.* TO ${SERVICE}@'localhost' IDENTIFIED BY 'OpenStack123'"
    $MYSQL -e "GRANT ALL PRIVILEGES ON ${SERVICE}.* TO ${SERVICE}@'%'         IDENTIFIED BY 'OpenStack123'"
    $MYSQL -e "SHOW GRANTS FOR ${SERVICE}@'%'"
done
$MYSQL -e "SHOW DATABASES"
