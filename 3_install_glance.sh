#!/bin/bash
set -x
source 0_common.sh
source /root/keystonerc_admin
yum install -y openstack-glance python-glance python-glanceclient
openstack user create --password $PASSWORD glance
openstack role add --project service --user glance admin
if not_exists_in_openstack service glance; then
    openstack service create --name glance --description "OpenStack Image service" image; fi
if not_exists_in_openstack endpoint glance; then
    openstack endpoint create \
    --publicurl http://$VIP:$GLANCE_API_PORT \
    --internalurl http://$VIP:$GLANCE_API_PORT \
    --adminurl http://$VIP:$GLANCE_API_PORT \
    --region RegionOne image; fi
openstack-config --del /etc/glance/glance-api.conf keystone_authtoken 
$GLANCE_API_CONF DEFAULT verbose True
$GLANCE_API_CONF DEFAULT debug False
$GLANCE_API_CONF DEFAULT show_image_direct_url True
$GLANCE_API_CONF DEFAULT show_multiple_locations True
$GLANCE_API_CONF DEFAULT notification_driver messagingv2
$GLANCE_API_CONF DEFAULT rpc_backend 'rabbit'
$GLANCE_API_CONF DEFAULT registry_host $VIP
$GLANCE_API_CONF DEFAULT registry_port $GLANCE_REGISTRY_PORT
$GLANCE_API_CONF database connection mysql://glance:$DB_PASS@$DB_HOST:$DB_PORT/glance
$GLANCE_API_CONF keystone_authtoken auth_uri http://$VIP:$KEYSTONE_MAIN_PORT
$GLANCE_API_CONF keystone_authtoken auth_url http://$VIP:$KEYSTONE_ADMIN_PORT
$GLANCE_API_CONF keystone_authtoken auth_plugin password
$GLANCE_API_CONF keystone_authtoken project_domain_id default
$GLANCE_API_CONF keystone_authtoken user_domain_id default
$GLANCE_API_CONF keystone_authtoken project_name service
$GLANCE_API_CONF keystone_authtoken username glance
$GLANCE_API_CONF keystone_authtoken password $PASSWORD
$GLANCE_API_CONF paste_deploy config_file /usr/share/glance/glance-api-dist-paste.ini
$GLANCE_API_CONF paste_deploy flavor keystone
$GLANCE_API_CONF oslo_messaging_rabbit rabbit_userid $RABBIT_USER
$GLANCE_API_CONF oslo_messaging_rabbit rabbit_password $RABBIT_PASS
$GLANCE_API_CONF oslo_messaging_rabbit rabbit_hosts $RABBIT_HOST
$GLANCE_API_CONF oslo_messaging_rabbit rabbit_retry_interval 1
$GLANCE_API_CONF oslo_messaging_rabbit rabbit_retry_backoff 2
$GLANCE_API_CONF oslo_messaging_rabbit rabbit_max_retries 0
$GLANCE_API_CONF oslo_messaging_rabbit rabbit_ha_queues true
$GLANCE_API_CONF oslo_messaging_rabbit amqp_durable_queues true
$GLANCE_API_CONF oslo_messaging_rabbit amqp_auto_delete true
$GLANCE_API_CONF glance_store default_store file
$GLANCE_API_CONF glance_store filesystem_store_datadir /var/lib/glance/images/
openstack-config --del /etc/glance/glance-registry.conf keystone_authtoken
$GLANCE_REGISTRY_CONF database connection mysql://glance:$DB_PASS@$DB_HOST:$DB_PORT/glance
$GLANCE_REGISTRY_CONF keystone_authtoken auth_uri http://$VIP:$KEYSTONE_MAIN_PORT
$GLANCE_REGISTRY_CONF keystone_authtoken auth_url http://$VIP:$KEYSTONE_ADMIN_PORT
$GLANCE_REGISTRY_CONF keystone_authtoken auth_plugin password
$GLANCE_REGISTRY_CONF keystone_authtoken project_domain_id default
$GLANCE_REGISTRY_CONF keystone_authtoken user_domain_id default
$GLANCE_REGISTRY_CONF keystone_authtoken project_name service
$GLANCE_REGISTRY_CONF keystone_authtoken username glance
$GLANCE_REGISTRY_CONF keystone_authtoken password $PASSWORD
$GLANCE_REGISTRY_CONF paste_deploy flavor keystone
su -s /bin/sh -c "glance-manage db_sync" glance 
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl restart openstack-glance-api.service openstack-glance-registry.service
