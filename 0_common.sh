unset http_proxy

IS_CONTROLLER_NODE=1
IS_COMPUTE_NODE=1

VIP=cluster
VIP_IP=10.10.119.100
PASSWORD=OpenStack123
DB_PASS=$PASSWORD
DB_HOST=$VIP
DB_PORT=4407
MY_IP=`hostname -I | awk '{print $1}'`
RABBIT_HOST=$VIP
RABBIT_USER=openstack
RABBIT_PASS=OpenStack123
KEYSTONE_ADMIN_PORT=46468
KEYSTONE_MAIN_PORT=6000
GLANCE_API_PORT=9393
GLANCE_REGISTRY_PORT=9494
NOVA_API_PORT=9885
NOVA_METADATA_PORT=9886
NEUTRON_API_PORT=9797
CINDER_API_PORT=9887

NOVA_CONF='openstack-config --set /etc/nova/nova.conf'
KEYSTONE_CONF='openstack-config --set /etc/keystone/keystone.conf'
GLANCE_API_CONF='openstack-config --set /etc/glance/glance-api.conf'
GLANCE_REGISTRY_CONF='openstack-config --set /etc/glance/glance-registry.conf'
NEUTRON_CONF='openstack-config --set /etc/neutron/neutron.conf'
NEUTRON_PLUGIN_CONF='openstack-config --set /etc/neutron/plugin.ini'
NEUTRON_L3AGENT_CONF='openstack-config --set /etc/neutron/l3_agent.ini'
NEUTRON_DHCP_CONF='openstack-config --set /etc/neutron/dhcp_agent.ini'
NEUTRON_METADATA_CONF='openstack-config --set /etc/neutron/metadata_agent.ini'
CINDER_CONF='openstack-config --set /etc/cinder/cinder.conf'

not_exists_in_openstack() {
    if openstack $1 list | grep -q $2 >/dev/null 2>&1 
    then return 1
    else return 0
    fi
}
ADMIN_TOKEN=653f52c4feaddf905fda
