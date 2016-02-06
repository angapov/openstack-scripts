#!/bin/bash
source 0_common.sh
yum install openstack-dashboard httpd mod_wsgi memcached python-memcached
rm -f /usr/share/openstack-dashboard/openstack_dashboard/enabled/_99_customization.py*
sed -i "s/^ALLOWED_HOSTS.*/ALLOWED_HOSTS = '*'/"
sed -i "s/^OPENSTACK_HOST.*/OPENSTACK_HOST=$VIP_IP/"
