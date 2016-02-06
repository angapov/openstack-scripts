#!/bin/bash
set -x
source 0_common.sh
source /root/keystonerc_admin
yum install -y openstack-neutron openstack-neutron-ml2 python-neutronclient which \
    openstack-neutron-openvswitch openstack-neutron-fwaas
ln -sf /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' \
  /usr/lib/systemd/system/neutron-openvswitch-agent.service
echo "net.ipv4.ip_forward=1"             >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0"     >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p
openstack user create --password $PASSWORD neutron
openstack role add --project service --user neutron admin
if not_exists_in_openstack service neutron; then 
    openstack service create --name neutron --description "OpenStack Networking" network; fi
if not_exists_in_openstack endpoint neutron; then 
    openstack endpoint create \
    --publicurl     http://$VIP:$NEUTRON_API_PORT \
    --adminurl      http://$VIP:$NEUTRON_API_PORT \
    --internalurl   http://$VIP:$NEUTRON_API_PORT \
    --region RegionOne network; fi
$NEUTRON_CONF keystone_authtoken auth_uri http://$VIP:$KEYSTONE_MAIN_PORT
$NEUTRON_CONF keystone_authtoken auth_url http://$VIP:$KEYSTONE_ADMIN_PORT
$NEUTRON_CONF keystone_authtoken auth_plugin password
$NEUTRON_CONF keystone_authtoken project_domain_id default
$NEUTRON_CONF keystone_authtoken user_domain_id default
$NEUTRON_CONF keystone_authtoken project_name service
$NEUTRON_CONF keystone_authtoken username neutron
$NEUTRON_CONF keystone_authtoken password $PASSWORD
$NEUTRON_CONF database connection mysql://neutron:$DB_PASS@$DB_HOST:$DB_PORT/neutron
$NEUTRON_CONF oslo_messaging_rabbit amqp_durable_queues true
$NEUTRON_CONF oslo_messaging_rabbit amqp_auto_delete true
$NEUTRON_CONF oslo_messaging_rabbit rabbit_hosts $RABBIT_HOST
$NEUTRON_CONF oslo_messaging_rabbit rabbit_userid $RABBIT_USER
$NEUTRON_CONF oslo_messaging_rabbit rabbit_password $RABBIT_PASS
$NEUTRON_CONF oslo_messaging_rabbit rabbit_retry_interval 1
$NEUTRON_CONF oslo_messaging_rabbit rabbit_retry_backoff 2
$NEUTRON_CONF oslo_messaging_rabbit rabbit_max_retries 0
$NEUTRON_CONF oslo_messaging_rabbit rabbit_ha_queues true
$NEUTRON_CONF DEFAULT rpc_backend rabbit
$NEUTRON_CONF DEFAULT max_l3_agents_per_router 2
$NEUTRON_CONF DEFAULT notify_nova_on_port_status_changes True
$NEUTRON_CONF DEFAULT notify_nova_on_port_data_changes True
$NEUTRON_CONF DEFAULT verbose True
$NEUTRON_CONF DEFAULT debug False
$NEUTRON_CONF DEFAULT router_distributed False
$NEUTRON_CONF DEFAULT core_plugin ml2
$NEUTRON_CONF DEFAULT service_plugins router,firewall
$NEUTRON_CONF DEFAULT auth_strategy keystone
$NEUTRON_CONF DEFAULT allow_overlapping_ips True
$NEUTRON_CONF DEFAULT force_gateway_on_subnet True
$NEUTRON_CONF DEFAULT allow_automatic_l3agent_failover True
$NEUTRON_CONF DEFAULT dhcp_agents_per_network 2
$NEUTRON_CONF DEFAULT nova_url http://$VIP:$NOVA_API_PORT/v2
$NEUTRON_CONF nova auth_url http://$VIP:$KEYSTONE_ADMIN_PORT
$NEUTRON_CONF nova auth_plugin password
$NEUTRON_CONF nova project_domain_id default
$NEUTRON_CONF nova user_domain_id default
$NEUTRON_CONF nova region_name RegionOne
$NEUTRON_CONF nova project_name service
$NEUTRON_CONF nova username nova
$NEUTRON_CONF nova password $PASSWORD

$NEUTRON_PLUGIN_CONF ml2 type_drivers flat,gre,vlan
$NEUTRON_PLUGIN_CONF ml2 tenant_network_types gre
$NEUTRON_PLUGIN_CONF ml2 mechanism_drivers openvswitch
$NEUTRON_PLUGIN_CONF ml2_type_flat flat_networks default
$NEUTRON_PLUGIN_CONF ml2_type_gre tunnel_id_ranges 1:1000
$NEUTRON_PLUGIN_CONF securitygroup enable_security_group True
$NEUTRON_PLUGIN_CONF securitygroup enable_ipset True
$NEUTRON_PLUGIN_CONF securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
$NEUTRON_PLUGIN_CONF ovs intergration_bridge br-int
$NEUTRON_PLUGIN_CONF ovs local_ip $MY_IP
$NEUTRON_PLUGIN_CONF ovs bridge_mappings default:br-ex
$NEUTRON_PLUGIN_CONF agent tunnel_types gre

$NEUTRON_L3AGENT_CONF DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
$NEUTRON_L3AGENT_CONF DEFAULT use_namespaces True
$NEUTRON_L3AGENT_CONF DEFAULT external_network_bridge
$NEUTRON_L3AGENT_CONF DEFAULT router_delete_namespaces True

$NEUTRON_DHCP_CONF DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
$NEUTRON_DHCP_CONF DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
$NEUTRON_DHCP_CONF DEFAULT dhcp_delete_namespaces True
$NEUTRON_DHCP_CONF DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf
echo "dhcp-option-force=26,1454" > /etc/neutron/dnsmasq-neutron.conf

$NEUTRON_METADATA_CONF DEFAULT auth_url http://$VIP:$KEYSTONE_ADMIN_PORT
$NEUTRON_METADATA_CONF DEFAULT auth_region RegionOne
$NEUTRON_METADATA_CONF DEFAULT admin_tenant_name service
$NEUTRON_METADATA_CONF DEFAULT admin_user neutron
$NEUTRON_METADATA_CONF DEFAULT admin_password $PASSWORD
$NEUTRON_METADATA_CONF DEFAULT auth_uri http://$VIP:$KEYSTONE_MAIN_PORT
$NEUTRON_METADATA_CONF DEFAULT auth_plugin password
$NEUTRON_METADATA_CONF DEFAULT project_domain_id default
$NEUTRON_METADATA_CONF DEFAULT user_domain_id default
$NEUTRON_METADATA_CONF DEFAULT project_name service
$NEUTRON_METADATA_CONF DEFAULT username neutron
$NEUTRON_METADATA_CONF DEFAULT password $PASSWORD
$NEUTRON_METADATA_CONF DEFAULT nova_metadata_ip $VIP
$NEUTRON_METADATA_CONF DEFAULT nova_metadata_port $NOVA_METADATA_PORT 
$NEUTRON_METADATA_CONF DEFAULT metadata_proxy_shared_secret $PASSWORD

openstack-config --set /etc/neutron/fwaas_driver.ini fwaas driver neutron_fwaas.services.firewall.drivers.linux.iptables_fwaas.IptablesFwaasDriver
openstack-config --set /etc/neutron/fwaas_driver.ini fwaas enabled True

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugin.ini upgrade head" neutron || exit 1

if [ "$IS_CONTROLLER_NODE" ]; then
    systemctl enable openstack-nova-api openstack-nova-scheduler openstack-nova-conductor neutron-l3-agent \
        neutron-dhcp-agent neutron-server neutron-metadata-agent neutron-ovs-cleanup
    systemctl restart openstack-nova-api openstack-nova-scheduler openstack-nova-conductor neutron-l3-agent \
        neutron-dhcp-agent neutron-server neutron-metadata-agent neutron-ovs-cleanup
fi
systemctl enable openvswitch neutron-openvswitch-agent
systemctl restart openvswitch neutron-openvswitch-agent

if [ "$IS_COMPUTE_NODE" ]; then
    echo "net.bridge.bridge-nf-call-iptables=1"  >> /etc/sysctl.conf
    echo "net.bridge.bridge-nf-call-ip6tables=1" >> /etc/sysctl.conf
    sysctl -p
    systemctl restart openstack-nova-compute.service
fi

