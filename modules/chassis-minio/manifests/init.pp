# A Chassis extension to install and configure Fake S3
class chassis-minio (
  $config,
) {

  # Default settings for install
  $defaults = {
    'port'  => 4571,
    'sync'  => true,
    'debug' => false,
  }

  # Allow override from config.yaml
  $options = deep_merge($defaults, $config[minio])

  if ( !empty($config[disabled_extensions]) and 'chassis/chassis-minio' in $config[disabled_extensions] ) {

    service { "minio file system sync":
      ensure   => 'stopped',
      provider => 'base',
      binary   => "/usr/local/bin/mc mirror -w local/chassis/uploads ${content}/uploads",
    }

    file { '/vagrant/extensions/chassis-minio/local-config.php':
      ensure => 'absent',
    }

    file { "/etc/nginx/sites-available/${fqdn}.d/minio.nginx.conf":
      ensure => 'absent',
      notify => Service['nginx'],
    }

    service { 'minio':
      ensure => 'stopped',
      enable => false,
    }

  } else {

    $port = $options[port]

    class { 'minio':
      package_ensure => 'present',
      listen_ip      => '127.0.0.1',
      listen_port    => $port,
      configuration  => {
        'credential' => {
          'accessKey' => 'ADMIN',
          'secretKey' => 'PASSWORD',
        },
        'region'     => 'us-east-1',
        'browser'    => 'on',
      }
    }

    # Install Minio Client
    exec { 'mc':
      command => '/usr/bin/wget https://dl.minio.io/client/mc/release/linux-amd64/mc',
      unless  => '/usr/bin/test -f mc',
      cwd     => '/home/vagrant',
      require => [ Service['minio'] ],
    } ->
    exec { '/bin/chmod +x mc':
      cwd    => '/home/vagrant',
      unless => '/usr/bin/test `which mc`'
    } ->
    exec { '/bin/ln -sf /home/vagrant/mc /usr/local/bin/mc':
      unless => '/usr/bin/test `which mc`',
    } ->
    file { '/home/vagrant/.mc':
      ensure => 'directory',
      owner  => 'vagrant',
    } ->
    file { '/home/vagrant/.mc/config.json':
      ensure  => 'present',
      content => template('chassis-minio/config.json.erb'),
      owner   => 'vagrant',
    }

    # Create default bucket.
    exec { 'mc mb local/chassis':
      command => "/usr/local/bin/mc mb local/chassis",
      user    => 'vagrant',
      unless  => "/usr/local/bin/mc ls local/chassis",
      require => Exec['mc'],
    } ->
    exec { 'mc policy public local/chassis':
      command => '/usr/local/bin/mc policy public local/chassis',
      unless  => '/usr/local/bin/mc policy local/chassis | grep "public"',
    }

    $content = $config[mapped_paths][content]

    # Sync existing uploads both ways
    exec { "mc mirror ${content}/uploads local/chassis/uploads":
      command => "/usr/local/bin/mc mirror ${content}/uploads local/chassis/uploads",
      user    => 'vagrant',
      onlyif  => "/usr/bin/test -d ${content}/uploads",
      require => [
        Exec['mc mb local/chassis'],
      ],
    }

    service { "minio file system sync":
      ensure   => 'running',
      provider => 'base',
      binary   => "/usr/local/bin/mc mirror -w local/chassis/uploads ${content}/uploads",
      require  => Exec["mc mirror ${content}/uploads local/chassis/uploads"]
    }

    # Configure WP
    file { '/vagrant/extensions/chassis-minio/local-config.php':
      ensure  => 'present',
      content => template('chassis-minio/local-config.php.erb'),
    }

    # Configure nginx
    file { "/etc/nginx/sites-available/${fqdn}.d/minio.nginx.conf":
      ensure  => 'present',
      content => template('chassis-minio/nginx.conf.erb'),
      notify  => Service['nginx'],
    }

  }

}
