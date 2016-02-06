$admin_key = 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
$mon_key = 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
$bootstrap_osd_key = 'AQAIYQpWbquCDBAAMZK3m5XBLDG7sePHlYE98w=='
$fsid = '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'

class { 'ceph::repo': 
    release => 'hammer',
}
class { 'ceph':
    fsid                        => $fsid,
    mon_initial_members         => 'master,minion1,minion2',
    mon_host                    => '10.10.119.91,10.10.119.92,10.10.119.93',
    authentication_type         => 'cephx',
    osd_pool_default_size       => '2',
    osd_pool_default_min_size   => '1',
}

ceph::mon { $::hostname:
    public_addr => $::ipaddress,
    key => $mon_key,
}

Ceph::Key {
    inject         => true,
    inject_as_id   => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
}

ceph::key { 'client.admin':
    secret  => $admin_key,
    cap_mon => 'allow *',
    cap_osd => 'allow *',
    cap_mds => 'allow',
}

ceph::key { 'client.bootstrap-osd':
    keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
    secret  => $bootstrap_osd_key,
    cap_mon => 'allow profile bootstrap-osd',
}

ceph_config {
    'global/osd_journal_size': value => '10240';
}

ceph::osd { '/dev/sdb': }
ceph::osd { '/dev/sdc': }
