# Changelog

## [3.0.0]

Breaking release: the CLI is now flat and the `stack <service> <command>` form is gone. Scripts and aliases built on the old form need updating.

### Added

* Now GDRCD stack can be installed through a single command (view README for details)
* Add `upgrade` command, updating the core while leaving `.env`, `www`, `services` and `logs` untouched (works with or without GIT)
* Add PHP 8.5 support
* Add `database` service healthcheck
* Add `.dockerignore` file

### Updated

* Generic commands take a list of services (e.g. `stack restart webserver database`). With no arguments they act on the whole stack
* `import`, `export` and `refresh` are now top level commands, replacing `database import`, `database export` and `database refresh`
* `enable` and `disable` are top level commands, replacing `service enable` and `service disable`
* The `webserver` image is tagged per PHP version
* Now Nginx and PHP configurations are mounted from the host
* Reduce webserver build context to the service directory
* Run with `sudo`, `install` targets `/usr/local/bin` instead of `/root/.local/bin`
* Update the README with new commands and instructions

### Fixed

* Fix missing MySQL authentication in `database export` and `database import`
* PHP extensions built into the image were never loaded, because mounting the configuration hid the files generated during the build
* Fix `fastcgi_pass` pointing at the wrong address
* Disabling an optional service also wiped the others, and state changes did not reach the Compose profiles until the next command
* Fix never defined per service form
* Fix `recreate` did not work after `clean`
* Fix cryptic error when `.env` file is missing
* Files written by PHP now belong to the host user and no longer need `sudo` to be edited or removed
* Running the stack with a shell other than bash now fails with a clear message instead of misbehaving
* Messages and errors with invalid arguments are no longer silently ignored

### Removed

* Remove duplicated per service commands
* Remove `www-cache` volume, no longer needed now
* Remove the memcached daemon from the webserver containers
* Remove PHP extensions unused by the engine (PDO, intl, gd, gettext and tokenizer). `mcrypt` is kept on PHP 5.6 only

**Full Changelog**: https://github.com/GDRCD/stack/compare/v2.3.2...v3.0.0
