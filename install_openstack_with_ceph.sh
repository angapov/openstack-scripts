#!/bin/bash
yum install -y git puppet
git clone https://github.com/stackforge/puppet-ceph.git /etc/puppet/modules/ceph
puppet module install openstack/cinder
puppet module install puppetlabs-concat
puppet module install puppetlabs-stdlib
puppet module install puppetlabs-inifile
if [ -b /dev/vdb ]
then 
    echo -e "o\ny\nw\ny\n" | gdisk /dev/vdb && \
    puppet apply tools/ceph.pp || exit 1
else
    echo "Disk /dev/vdb not found. Is volume attached to this VM?"; exit 1
fi
tools/install_openstack_kilo.sh   && \
tools/update_openstack.sh 	  && \
tools/cinder_ceph_integration.sh  && \
tools/nova_ceph_integration.sh    && \
tools/glance_ceph_integration.sh  && \
tools/make_symlinks.sh

source /root/keystonerc_admin
glance image-create --name "cirros-0.3.4-x86_64" --file /root/cirros-0.3.4-x86_64-disk.img --disk-format raw --container-format bare
neutron net-create demo-net
neutron subnet-create demo-net 192.168.1.0/24 --name demo-subnet --gateway 192.168.1.1
