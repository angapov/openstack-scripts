#!/bin/bash
set -x
source 0_common.sh
source /root/keystonerc_admin
yum install -y openstack-cinder python-cinderclient python-oslo-db
openstack user create --password $PASSWORD cinder
openstack role add --project service --user cinder admin
if not_exists_in_openstack service cinder; then
    openstack service create --name cinder   --description "OpenStack Block Storage" volume
    openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2; fi
if not_exists_in_openstack endpoint cinder; then
    openstack endpoint create \
    --publicurl http://$VIP:$CINDER_API_PORT/v2/%\(tenant_id\)s \
    --internalurl http://$VIP:$CINDER_API_PORT/v2/%\(tenant_id\)s \
    --adminurl http://$VIP:$CINDER_API_PORT/v2/%\(tenant_id\)s \
    --region RegionOne volume
    openstack endpoint create \
    --publicurl http://$VIP:$CINDER_API_PORT/v2/%\(tenant_id\)s \
    --internalurl http://$VIP:$CINDER_API_PORT/v2/%\(tenant_id\)s \
    --adminurl http://$VIP:$CINDER_API_PORT/v2/%\(tenant_id\)s \
    --region RegionOne volumev2; fi
cp /usr/share/cinder/cinder-dist.conf /etc/cinder/cinder.conf
chown -R cinder:cinder /etc/cinder/cinder.conf
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password $PASSWORD
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://$VIP:$KEYSTONE_MAIN_PORT
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://$VIP:$KEYSTONE_ADMIN_PORT
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_plugin password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_id default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_id default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
openstack-config --set /etc/cinder/cinder.conf database connection mysql://cinder:$DB_PASS@$DB_HOST:$DB_PORT/cinder
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password OpenStack123
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_hosts $RABBIT_HOST
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit amqp_durable_queues true
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit amqp_auto_delete true
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/cinder/cinder.conf DEFAULT host $VIP
openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip $MY_IP
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm
openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers $VIP:$GLANCE_API_PORT
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_version 2
openstack-config --set /etc/cinder/cinder.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
openstack-config --set /etc/cinder/cinder.conf lvm volume_group cinder-volumes
openstack-config --set /etc/cinder/cinder.conf lvm iscsi_protocol iscsi
openstack-config --set /etc/cinder/cinder.conf lvm volume_backend_name LVM_iSCSI
openstack-config --set /etc/cinder/cinder.conf lvm iscsi_helper lioadm

su -s /bin/sh -c "cinder-manage db sync" cinder

systemctl enable  openstack-cinder-api openstack-cinder-scheduler openstack-cinder-volume target
systemctl restart openstack-cinder-api openstack-cinder-scheduler openstack-cinder-volume target
