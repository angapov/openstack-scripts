$admin_key  = 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
$mon_key    = 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
$bootstrap_osd_key = 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A=='

class { 'ceph::repo':
  release => 'hammer',
}
ceph::mon { $::hostname :
  public_addr => $::ipaddress,
  key         => $mon_key
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
  secret       => $bootstrap_osd_key,
  cap_mon      => 'allow profile bootstrap-osd',
}
class { 'ceph':
  fsid                       => generate('/usr/bin/uuidgen'),
  mon_initial_members        => $::hostname,
  mon_host                   => $::ipaddress,
  authentication_type        => 'cephx',
  osd_pool_default_size      => '1',
  osd_pool_default_min_size  => '1',
}
service { 'ceph':
  enable => true,
}
ceph_config {
 'global/osd_journal_size': value => '200';
}
ceph::osd { '/dev/vdb': }
