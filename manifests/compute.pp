class ceph::compute(
  $poolname = 'volumes',
  $fsid = $::ceph_monitor_fsid,
) {

  include 'ceph::package'

  Package['ceph'] -> Ceph::Key <<| title == 'admin' |>>

  class { 'ceph::apt::ceph': release => $::ceph_release }

  package { 'ceph-common':
    ensure => present,
    require => Apt::Source['ceph'],
  }

  package { 'python-ceph':
    ensure => present,
    require => Apt::Source['ceph'],
  }

  class { 'ceph::conf':
    fsid => $fsid,
  }

  file { '/etc/ceph/secret.xml':
    content => template('ceph/secret.xml-compute.erb'),
    require => Package['ceph-common'],
  }

  exec { 'get-or-set volumes key':
    command => "ceph auth get-or-create client.volumes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=${poolname}' > /etc/ceph/client.volumes",
    require => [ Package['ceph'], Ceph::Key['admin'] ],
  }

  exec { 'get-or-set virsh secret':
    command => '/usr/bin/virsh secret-define --file secret.xml | /usr/bin/awk \'{print $2}\' | sed \'/^$/d\' > /etc/ceph/virsh.secret',
    creates => "/etc/ceph/virsh.secret",
    require => [ Package['ceph'], Ceph::Key['admin'], File['/etc/ceph/secret.xml'] ],
  }

  exec { 'set-secret-value virsh':
    command => "virsh secret-set-value --secret $(cat /etc/ceph/virsh.secret) --base64 $(ceph auth get-key client.volumes)",
    require => Exec['get-or-set virsh secret'],
  }

  exec { 'create the pool':
    command => "ceph osd pool create volumes 128",
    require => Exec['set-secret-value virsh'],
  }

}

