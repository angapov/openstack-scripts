#!/bin/bash
CINDER_CONF="openstack-config --set /etc/cinder/cinder.conf"
source /root/keystonerc_admin
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=rbd, allow rwx pool=volumes'
ceph auth get-or-create client.cinder > /etc/ceph/ceph.client.cinder.keyring
ceph auth get-key client.cinder > /etc/ceph/client.cinder.key
cat > /etc/ceph/secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>457eb676-33da-42ec-9a8c-9293d545c337</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
virsh secret-define --file /etc/ceph/secret.xml
virsh secret-set-value --secret 457eb676-33da-42ec-9a8c-9293d545c337 --base64 $(cat /etc/ceph/client.cinder.key)
$CINDER_CONF DEFAULT enabled_backends ceph,lvm
$CINDER_CONF DEFAULT glance_api_version 2
$CINDER_CONF ceph volume_driver cinder.volume.drivers.rbd.RBDDriver
$CINDER_CONF ceph rbd_pool rbd
$CINDER_CONF ceph rbd_user cinder
$CINDER_CONF ceph rbd_ceph_conf /etc/ceph/ceph.conf
$CINDER_CONF ceph rbd_secret_uuid 457eb676-33da-42ec-9a8c-9293d545c337
$CINDER_CONF ceph rbd_flatten_volume_from_snapshot false 
$CINDER_CONF ceph rbd_max_clone_depth 5
$CINDER_CONF ceph rbd_store_chunk_size 4
$CINDER_CONF ceph rados_connect_timeout -1
$CINDER_CONF ceph volume_backend_name ceph
if ! cinder type-list | grep -q ceph; 
then 
    cinder type-create ceph
    cinder type-key ceph set volume_backend_name=ceph
fi
systemctl restart openstack-cinder-volume
