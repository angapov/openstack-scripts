#!/bin/bash
set -x
source 0_common.sh
if ! [ "$ADMIN_TOKEN" ]; then 
    ADMIN_TOKEN=`openssl rand -hex 10` 
    echo "ADMIN_TOKEN=$ADMIN_TOKEN" >> 0_common.sh
fi
yum install -y openstack-keystone httpd mod_wsgi python-openstackclient \
    memcached python-memcached openstack-utils
systemctl enable memcached && systemctl start memcached
$KEYSTONE_CONF DEFAULT  admin_token $ADMIN_TOKEN
$KEYSTONE_CONF DEFAULT  rpc_backend rabbit 
$KEYSTONE_CONF database connection  mysql://keystone:$DB_PASS@$DB_HOST:$DB_PORT/keystone
$KEYSTONE_CONF memcache servers     `hostname`:11211 
$KEYSTONE_CONF token    provider    keystone.token.providers.uuid.Provider  
$KEYSTONE_CONF token    driver      keystone.token.persistence.backends.memcache.Token
$KEYSTONE_CONF revoke   driver      keystone.contrib.revoke.backends.sql.Revoke
$KEYSTONE_CONF oslo_messaging_rabbit amqp_auto_delete true
$KEYSTONE_CONF oslo_messaging_rabbit amqp_durable_queues true
su -s /bin/sh -c "keystone-manage db_sync" keystone
cat > /etc/httpd/conf.d/wsgi-keystone.conf <<EOF
Listen $MY_IP:5000
Listen $MY_IP:35357

<VirtualHost $MY_IP:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LogLevel info
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined
</VirtualHost>

<VirtualHost $MY_IP:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /var/www/cgi-bin/keystone/admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LogLevel info
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined
</VirtualHost>
EOF
mkdir -p /var/www/cgi-bin/keystone
http_proxy=10.10.119.11:3128 curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo \
    | tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin
chown -R keystone:keystone /var/www/cgi-bin/keystone
chmod 755 /var/www/cgi-bin/keystone/*
systemctl enable httpd && systemctl restart httpd || exit 1
export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://$VIP:$KEYSTONE_ADMIN_PORT/v2.0
if not_exists_in_openstack service keystone; then 
    openstack service create --name keystone --description "OpenStack Identity" identity || exit 1; fi
if not_exists_in_openstack endpoint keystone; then
    openstack endpoint create --publicurl http://$VIP:$KEYSTONE_MAIN_PORT/v2.0 \
    --internalurl http://$VIP:$KEYSTONE_MAIN_PORT/v2.0 \
    --adminurl http://$VIP:$KEYSTONE_ADMIN_PORT/v2.0 \
    --region RegionOne identity; fi
if not_exists_in_openstack project admin; then
    openstack project create --description "Admin Project" admin; fi
if not_exists_in_openstack user admin; then
    openstack user create --password $PASSWORD admin
    openstack role create admin
    openstack role add --project admin --user admin admin; fi
if not_exists_in_openstack project service; then
    openstack project create --description "Service Project" service; fi
if not_exists_in_openstack project demo; then
    openstack project create --description "Demo Project" demo; fi
if not_exists_in_openstack user demo; then
    openstack user create --password $PASSWORD demo
    openstack role create user
    openstack role add --project demo --user demo user; fi
cat > /root/keystonerc_admin <<EOF
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$PASSWORD
export OS_AUTH_URL=http://$VIP:$KEYSTONE_ADMIN_PORT/v3
export OS_IMAGE_API_VERSION=2
export OS_VOLUME_API_VERSION=2
export OS_REGION_NAME=RegionOne
EOF
unset OS_TOKEN OS_URL
