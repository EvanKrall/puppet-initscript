# initscript
Puppet module for creating init scripts

##Usage

To create an init script:
```
initscript { 'sleep':
  command => ['/bin/cat'],
}
```

This will auto-detect your init system based on your operating system,
create an init script for the command you specified,
and launch the service.

##Development
Open an [issue](https://github.com/EvanKrall/puppet-initscript/issues) or
[fork](https://github.com/EvanKrall/puppet-initscript/fork) and open a
[Pull Request](https://github.com/EvanKrall/puppet-initscript/pulls)

##Init system support

This module currently supports:

- Systemd
- Upstart
- Launchd
- SysV init scripts
 - Debian
 - SLES
 - Red Hat


##Acknowledgements

Much of the initial code was adapted from the init script templates at [solarkennedy/puppet-consul](https://github.com/solarkennedy/puppet-consul). Thank you to the contributors to that project.