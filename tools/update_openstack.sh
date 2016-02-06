#!/bin/bash
systemctl stop NetworkManager && systemctl disable NetworkManager
chkconfig network on && service network start
cat > /etc/yum.repos.d/iclcloud.repo <<EOF
[ICL_Cloud_repo]
name=iclcloud
baseurl=http://172.31.246.13/rpms/testing
enabled=1
gpgcheck=0
priority=1
EOF
if rpm -q openstack-dashboard-theme;    then yum remove -y openstack-dashboard-theme;    fi
if rpm -q openstack-ceilometer-polling; then yum remove -y openstack-ceilometer-polling; fi
yum update -y openstack-dashboard python-django-horizon 
rm -f /usr/share/openstack-dashboard/openstack_dashboard/enabled/_99_customization.py* 
openstack-service restart
systemctl restart httpd
