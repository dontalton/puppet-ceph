


class ceph::compute(
  keyname  = 'volumes',
  poolname = 'volumes',
) {

  $volume_keyname = "client.${keyname}"

  file { 'compute secret':
    content => template('secret.xml-compute.erb'),
  }

  exec { 'get-or-set volumes key':
    command => "ceph auth get-or-create $volume_keyname mon 'allow r' osd \
      'allow class-read object_prefix rbd_children, allow rwx pool=${poolname}"
  }

  exec { 'get-or-set virsh secret':
    command => "virsh secret-define --file secret.xml | awk '{print $2}' | \
      sed '/^$/d' > /etc/ceph/virsh.secret",
    onlyif  => 'test ! -f /etc/ceph/virsh.secret',
    require => File['compute secret'],
  }

  exec { 'set-secret-value virsh':
    command => "virsh secret-set-value --secret $(cat /etc/ceph/virsh.secret) \
      --base64 $(cat /etc/ceph/$volume_keyname",
    require => Exec['get-or-set virsh secret'],
  }

}
