#!/bin/bash

hostnamectl set-hostname controller
CONTROLLER_IP=$(ip address show dev eth0|grep ine|awk '{print $2}'|cut -d/ -f1)
echo "Your IP address is $CONTROLLER_IP"
echo "Please check that your DNS servers are correct"
echo "Current DNS configuration is "
echo "###############################"
cat /etc/resolv.conf
echo "###############################"
echo "$CONTROLLER_IP   controller" >> /etc/hosts

packstack  --debug --gen-answer-file=/root/packstack_answer_file.txt \
  --ssh-public-key=/root/.ssh/id_rsa.pub \
  --default-password=OpenStack123 \
  --mariadb-install=y \
  --os-glance-install=y \
  --os-cinder-install=y \
  --os-manila-install=n \
  --os-nova-install=y \
  --os-neutron-install=y \
  --os-horizon-install=y \
  --os-swift-install=n \
  --os-ceilometer-install=y \
  --os-heat-install=y \
  --os-sahara-install=n \
  --os-trove-install=n \
  --os-ironic-install=n \
  --os-client-install=y \
  --ntp-servers= \
  --nagios-install=n \
  --exclude-servers= \
  --os-debug-mode=n \
  --os-controller-host=$CONTROLLER_IP \
  --os-compute-hosts=$CONTROLLER_IP \
  --os-network-hosts=$CONTROLLER_IP \
  --os-vmware=n \
  --unsupported=n \
  --use-epel=y \
  --additional-repo= \
  --amqp-backend=rabbitmq \
  --amqp-host=$CONTROLLER_IP \
  --amqp-enable-ssl=n \
  --amqp-enable-auth=y \
  --amqp-auth-user=openstack \
  --amqp-auth-password=OpenStack123 \
  --mariadb-host=$CONTROLLER_IP \
  --mariadb-pw=OpenStack123 \
  --keystone-db-passwd=OpenStack123 \
  --keystone-region=RegionOne \
  --keystone-admin-email=admin@localhost \
  --keystone-admin-username=admin \
  --keystone-admin-passwd=OpenStack123 \
  --keystone-demo-passwd=OpenStack123 \
  --keystone-service-name=httpd \
  --keystone-identity-backend=sql \
  --glance-db-passwd=OpenStack123 \
  --glance-ks-passwd=OpenStack123 \
  --glance-backend=file \
  --cinder-db-passwd=OpenStack123 \
  --cinder-ks-passwd=OpenStack123 \
  --cinder-backend=lvm \
  --cinder-volumes-create=n \
  --cinder-volumes-size=20G \
  --nova-db-passwd=OpenStack123 \
  --nova-ks-passwd=OpenStack123 \
  --novasched-cpu-allocation-ratio=16.0 \
  --novasched-ram-allocation-ratio=3 \
  --novacompute-migrate-protocol=tcp \
  --nova-compute-manager=nova.compute.manager.ComputeManager \
  --os-neutron-ks-password=OpenStack123 \
  --os-neutron-db-password=OpenStack123 \
  --os-neutron-l3-ext-bridge=br-ex \
  --os-neutron-metadata-pw=OpenStack123 \
  --os-neutron-lbaas-install=y \
  --os-neutron-metering-agent-install=y \
  --neutron-fwaas=y \
  --os-neutron-ml2-type-drivers=gre \
  --os-neutron-ml2-tenant-network-types=gre \
  --os-neutron-ml2-mechanism-drivers=openvswitch \
  --os-neutron-ml2-flat-networks= \
  --os-neutron-ml2-vlan-ranges= \
  --os-neutron-ml2-tunnel-id-ranges=1:1000\
  --os-neutron-ml2-vxlan-group= \
  --os-neutron-ml2-vni-ranges= \
  --os-neutron-l2-agent=openvswitch \
  --os-neutron-lb-interface-mappings= \
  --os-neutron-ovs-bridge-mappings= \
  --os-neutron-ovs-bridge-interfaces= \
  --os-neutron-ovs-tunnel-if= \
  --os-neutron-ovs-vxlan-udp-port= \
  --os-horizon-ssl=n \
  --os-heat-mysql-password=OpenStack123 \
  --os-heat-ks-passwd=OpenStack123 \
  --os-heat-cloudwatch-install=y \
  --os-heat-cfn-install=y \
  --os-heat-domain=heat \
  --os-heat-domain-admin=heat_admin \
  --os-heat-domain-password=OpenStack123 \
  --provision-demo=n \
  --provision-tempest=n \
  --provision-all-in-one-ovs-bridge=n \
  --ceilometer-ks-passwd=OpenStack123 \
  --mongodb-host=$CONTROLLER_IP \
  --rh-username= \
  --rhn-satellite-server= \
  --rh-password= \
  --rh-enable-optional=n \
  --rh-proxy-host= \
  --rh-proxy-port= \
  --rh-proxy-user= \
  --rh-proxy-password= \
  --rhn-satellite-username= \
  --rhn-satellite-password= \
  --rhn-satellite-activation-key= \
  --rhn-satellite-cacert= \
  --rhn-satellite-profile= \
  --rhn-satellite-flags=norhnsd \
  --rhn-satellite-proxy-host= \
  --rhn-satellite-proxy-username= \
  --rhn-satellite-proxy-password= \
  --redis-master-host=$CONTROLLER_IP \
  --redis-port=6379 \
  --redis-ha=n

packstack  --debug --answer-file=/root/packstack_answer_file.txt
