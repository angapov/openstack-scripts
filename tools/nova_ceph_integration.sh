#!/bin/bash
NOVA_CONF="openstack-config --set /etc/nova/nova.conf" 
$NOVA_CONF libvirt storages qcow2,rbd:ceph/rbd
$NOVA_CONF libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
$NOVA_CONF libvirt rbd_user cinder
$NOVA_CONF libvirt rbd_secret_uuid 457eb676-33da-42ec-9a8c-9293d545c337
$NOVA_CONF libvirt disk_cachemodes network=writeback
$NOVA_CONF libvirt inject_password false
$NOVA_CONF libvirt inject_key  false
$NOVA_CONF libvirt inject_partition -2
$NOVA_CONF DEFAULT novncproxy_host `hostname -I` 
$NOVA_CONF DEFAULT scheduler_default_filters StorageFilter,RetryFilter,AvailabilityZoneFilter,RamFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter
$NOVA_CONF glance allowed_direct_url_schemes file,rbd
systemctl restart openstack-nova-compute
