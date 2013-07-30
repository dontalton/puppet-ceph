


class ceph::compute(
  keyname  = 'volumes',
  poolname = 'volumes',
) {

  $volume_keyname = "client.${keyname}"

  class { 'ceph::apt::ceph': release => $::ceph_release }  

  package { 'ceph-common':
    ensure => present,
    require => Apt::Source['ceph'],
  }

  package { 'python-ceph':
    ensure => present,
    require => Apt::Source['ceph'],
  }

  file { '/etc/ceph/secret.xml':
    content => template('secret.xml-compute.erb'),
    require => Package['ceph-common'],
  }

  exec { 'get-or-set volumes key':
    command => "ceph auth get-or-create $volume_keyname mon 'allow r' osd \
      'allow class-read object_prefix rbd_children, allow rwx pool=${poolname}",
    require => Package['ceph-common'],
  }

  exec { 'get-or-set virsh secret':
    command => "virsh secret-define --file secret.xml | awk '{print $2}' | \
      sed '/^$/d' > /etc/ceph/virsh.secret",
    onlyif  => 'test ! -f /etc/ceph/virsh.secret',
    require => File['/etc/ceph/secret.xml'],
  }

  exec { 'set-secret-value virsh':
    command => "virsh secret-set-value --secret $(cat /etc/ceph/virsh.secret) \
      --base64 $(cat /etc/ceph/$volume_keyname",
    require => Exec['get-or-set virsh secret'],
  }

}
