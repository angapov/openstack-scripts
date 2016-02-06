#!/bin/bash
GLANCE_CONF="openstack-config --set /etc/glance/glance-api.conf"
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=rbd, allow rwx pool=images'
ceph auth get-or-create client.glance > /etc/ceph/ceph.client.glance.keyring
$GLANCE_CONF DEFAULT show_image_direct_url True
$GLANCE_CONF glance_store default_store rbd
$GLANCE_CONF glance_store stores glance.store.filesystem.Store,glance.store.rbd.Store
$GLANCE_CONF glance_store rbd_store_pool rbd
$GLANCE_CONF glance_store rbd_store_user glance
$GLANCE_CONF glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
$GLANCE_CONF glance_store rbd_store_chunk_size 8
systemctl restart openstack-glance-api
