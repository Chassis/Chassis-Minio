# A Chassis extension to install and configure Minio Server and client
class chassis_minio (
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

  if ( !empty($config[disabled_extensions]) and 'chassis/chassis_minio' in $config[disabled_extensions] ) {

    exec { 'stop minio sync':
      command => '/usr/bin/killall -9 mc',
      onlyif  => '/bin/ps -ef | grep \'[m]c mirror\''
    }

    file { '/vagrant/extensions/chassis_minio/local-config.php':
      ensure => 'absent',
    }

    file { "/etc/nginx/sites-available/${::fqdn}.d/minio.nginx.conf":
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
    }
    -> exec { '/bin/chmod +x mc':
      cwd    => '/home/vagrant',
      unless => '/usr/bin/test `which mc`'
    }
    -> exec { '/bin/ln -sf /home/vagrant/mc /usr/local/bin/mc':
      unless => '/usr/bin/test `which mc`',
    }
    -> file { '/home/vagrant/.mc':
      ensure => 'directory',
      owner  => 'vagrant',
    }
    -> file { '/home/vagrant/.mc/config.json':
      ensure  => 'present',
      content => template('chassis_minio/config.json.erb'),
      owner   => 'vagrant',
    }
    -> file { '/root/.mc':
      ensure => 'directory',
    }
    -> file { '/root/.mc/config.json':
      ensure  => 'present',
      content => template('chassis_minio/config.json.erb'),
    }

    # Create default bucket.
    exec { 'mc mb local/chassis':
      command => '/usr/local/bin/mc mb local/chassis',
      unless  => '/usr/local/bin/mc ls local/chassis',
      require => Exec['mc'],
    }
    -> exec { 'mc policy public local/chassis':
      command => '/usr/local/bin/mc policy public local/chassis',
      unless  => '/usr/local/bin/mc policy local/chassis | grep "public"',
    }

    $content = $config[mapped_paths][content]

    # Sync existing uploads both ways
    file { 'minio static uploads directory':
      ensure => 'directory',
      path   => "${content}/uploads/",
      owner  => 'vagrant',
    }

    exec { "mc mirror ${content}/uploads/ local/chassis/uploads/":
      command => "/usr/local/bin/mc mirror ${content}/uploads/ local/chassis/uploads/",
      onlyif  => "/usr/bin/test -d ${content}/uploads",
      require => [
        Exec['mc mb local/chassis'] ,
        File['minio static uploads directory'],
      ],
    }

    service { 'minio sync service':
      ensure   => 'running',
      enable   => true,
      provider => 'base',
      start    => "/usr/local/bin/mc mirror -w local/chassis/uploads/ ${content}/uploads &>/dev/null &",
      stop     => 'killall -9 mc',
      require  => Exec["mc mirror ${content}/uploads/ local/chassis/uploads/"],
      status   => "ps -ef | grep '\\/bin\\/mc'",
    }

    # Configure WP
    file { '/vagrant/extensions/chassis_minio/local-config.php':
      ensure  => 'present',
      content => template('chassis_minio/local-config.php.erb'),
    }

    # Configure nginx
    file { "/etc/nginx/sites-available/${::fqdn}.d/minio.nginx.conf":
      ensure  => 'present',
      content => template('chassis_minio/nginx.conf.erb'),
      notify  => Service['nginx'],
    }

  }

}
