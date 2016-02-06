#!/bin/bash
set -x
source 0_common.sh
source /root/keystonerc_admin
if [ "$IS_CONTROLLER_NODE" ]; then
    yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor \
        openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler \
        python-novaclient
fi
if [ "$IS_COMPUTE_NODE" ]; then
    yum install -y openstack-nova-compute sysfsutils
fi
openstack user create --password $PASSWORD nova
openstack role add --project service --user nova admin
if not_exists_in_openstack service nova; then
    openstack service create --name nova --description "OpenStack Compute" compute
fi
if not_exists_in_openstack endpoint nova; then
    openstack endpoint create \
    --publicurl http://$VIP:$NOVA_API_PORT/v2/%\(tenant_id\)s \
    --internalurl http://$VIP:$NOVA_API_PORT/v2/%\(tenant_id\)s \
    --adminurl http://$VIP:$NOVA_API_PORT/v2/%\(tenant_id\)s \
    --region RegionOne compute
fi
$NOVA_CONF database connection mysql://nova:$DB_PASS@$DB_HOST:$DB_PORT/nova
$NOVA_CONF oslo_messaging_rabbit rabbit_userid $RABBIT_USER
$NOVA_CONF oslo_messaging_rabbit rabbit_password $RABBIT_PASS
$NOVA_CONF oslo_messaging_rabbit rabbit_hosts $RABBIT_HOST
$NOVA_CONF oslo_messaging_rabbit rabbit_retry_interval 1
$NOVA_CONF oslo_messaging_rabbit rabbit_retry_backoff 2
$NOVA_CONF oslo_messaging_rabbit rabbit_max_retries 0
$NOVA_CONF oslo_messaging_rabbit rabbit_ha_queues true
$NOVA_CONF oslo_messaging_rabbit amqp_durable_queues true
$NOVA_CONF oslo_messaging_rabbit amqp_auto_delete true
$NOVA_CONF DEFAULT verbose True
$NOVA_CONF DEFAULT rpc_backend rabbit
$NOVA_CONF DEFAULT auth_strategy keystone
$NOVA_CONF DEFAULT my_ip $MY_IP
$NOVA_CONF DEFAULT vncserver_listen $MY_IP
$NOVA_CONF DEFAULT vncserver_proxyclient_address $MY_IP
$NOVA_CONF DEFAULT vnc_enabled True
$NOVA_CONF DEFAULT novncproxy_base_url http://$VIP_IP/vnc_auto.html
$NOVA_CONF DEFAULT network_api_class nova.network.neutronv2.api.API
$NOVA_CONF DEFAULT security_group_api neutron
$NOVA_CONF DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
$NOVA_CONF DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
$NOVA_CONF keystone_authtoken auth_uri http://$VIP:$KEYSTONE_MAIN_PORT
$NOVA_CONF keystone_authtoken auth_url http://$VIP:$KEYSTONE_ADMIN_PORT
$NOVA_CONF keystone_authtoken auth_plugin password
$NOVA_CONF keystone_authtoken project_domain_id default
$NOVA_CONF keystone_authtoken user_domain_id default
$NOVA_CONF keystone_authtoken project_name service
$NOVA_CONF keystone_authtoken username nova
$NOVA_CONF keystone_authtoken password $PASSWORD
$NOVA_CONF glance host $VIP
$NOVA_CONF glance port $GLANCE_API_PORT
$NOVA_CONF glance allowed_direct_url_schemes rbd
$NOVA_CONF oslo_concurrency lock_path /var/lib/nova/tmp
$NOVA_CONF libvirt cpu_mode host-model
$NOVA_CONF neutron url http://$VIP:$NEUTRON_API_PORT
$NOVA_CONF neutron auth_strategy keystone
$NOVA_CONF neutron admin_auth_url http://$VIP:$KEYSTONE_ADMIN_PORT/v2.0
$NOVA_CONF neutron admin_tenant_name service
$NOVA_CONF neutron admin_username neutron
$NOVA_CONF neutron admin_password $PASSWORD
$NOVA_CONF neutron region_name RegionOne
$NOVA_CONF neutron service_metadata_proxy True
$NOVA_CONF neutron metadata_proxy_shared_secret $PASSWORD

su -s /bin/sh -c "nova-manage db sync" nova || exit 1

if [ "$IS_CONTROLLER_NODE" ]; then
    systemctl enable openstack-nova-api.service openstack-nova-cert.service \
        openstack-nova-consoleauth.service openstack-nova-scheduler.service \
        openstack-nova-conductor.service openstack-nova-novncproxy.service
    systemctl restart openstack-nova-api.service openstack-nova-cert.service \
        openstack-nova-consoleauth.service openstack-nova-scheduler.service \
        openstack-nova-conductor.service openstack-nova-novncproxy.service
fi
if [ "$IS_COMPUTE_NODE" ]; then
    systemctl enable libvirtd.service openstack-nova-compute.service
    systemctl restart libvirtd.service openstack-nova-compute.service
fi
