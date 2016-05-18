# == Define: initscript
#
# Given a command, creates an init script for that command and launches it.
#
# === Parameters
#
# [*command*]
#   An array of [command, arg, arg, ...] to execute. Special characters in
#   these will be quoted for safety.
#
# [*manage_service*]
#   Whether this module should manage a corresponding Service resource for
#   this init script.
#
# [*service_ensure*]
#   If $manage_service is set, this is passed as `ensure` to the service
#   resource.
#
# [*service_enable*]
#   If $manage_service is set, this is passed as `enable` to the service
#   resource.
#
# [*has_reload*]
#   Whether a soft reload can be triggered. See reload_command below.
#
# [*reload_command*]
#   The command to execute on a reload. If left undefined and has_reload is
#   true, a SIGHUP will be sent on reload.
#
# [*launchd_name*]
#   If we're creating a launchd init script (Darwin), this is used as the name
#   of the init script. Usually of the form com.domain.program.
#
# [*description*]
#   Some init systems like to have a description of the service.
#
# [*short_description*]
#   Some init systems like to have a short description of the service.
#
# [*init_style*]
#   Usually you can leave this un-set and it will be auto-detected, but if you
#   want to override the type of init script, set this.
#
define initscript(
  $command,
  $manage_service = true,
  $user = undef,
  $group = undef,
  $service_ensure = 'running',
  $service_enable = true,
  $has_reload = true,
  $reload_command = undef,
  $launchd_name = undef,
  $description = '',
  $short_description = '',
  $init_style = undef,
  $source_default_file = false,
  $default_file_path = undef,
) {
  validate_array($command)

  include initscript::params

  if $init_style == undef {
    $real_init_style = $::initscript::params::init_style
  } else {
    $real_init_style = $init_style
  }

  if $default_file_path == undef {
    case $real_init_style {
      'sysv_redhat' : {
        $real_default_file_path = "/etc/sysconfig/${name}"
      }
      default : {
        $real_default_file_path = "/etc/default/${name}"
      }
    }
  } else {
    $real_default_file_path = $default_file_path
  }

  if $source_default_file {
    case $real_init_style {
      'upstart', 'sysv_redhat' : {}
      default : { fail("source_default_file=true not supported on init style ${real_init_style}") }
    }
  }

  case $real_init_style {
    'upstart' : {
      file { "initscript ${name}":
        path    => "/etc/init/${name}.conf",
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('initscript/upstart.erb'),
      }
      file { "/etc/init.d/${name}":
        ensure => link,
        target => '/lib/init/upstart-job',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }
    }
    'systemd' : {
      file { "initscript ${name}":
        path    => "/lib/systemd/system/${name}.service",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => template('initscript/systemd.erb'),
      }
    }
    'sysv_redhat' : {
      file { "initscript ${name}":
        path    => "/etc/init.d/${name}",
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => template('initscript/sysv_redhat.erb')
      }
    }
    'sysv_debian' : {
      file { "initscript ${name}":
        path    => "/etc/init.d/${name}",
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => template('initscript/sysv_debian.erb')
      }
    }
    'sysv_sles' : {
      file { "initscript ${name}":
        path    => "/etc/init.d/${name}",
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        content => template('initscript/sysv_sles.erb')
      }
    }
    'launchd' : {
      validate_string($launchd_name)
      file { "initscript ${name}":
        path    => "/Library/LaunchDaemons/${launchd_name}.daemon.plist",
        mode    => '0644',
        owner   => 'root',
        group   => 'wheel',
        content => template('initscript/launchd.erb')
      }
    }
    default : {
      fail("I don't know how to create an init script for style ${real_init_style}")
    }
  }

  $init_selector = $real_init_style ? {
    'launchd' => $launchd_name,
    default   => $name,
  }

  if $manage_service {
    File["initscript ${name}"] ->
    service { $name:
      ensure => $service_ensure,
      name   => $init_selector,
      enable => $service_enable,
    }
  }
}
