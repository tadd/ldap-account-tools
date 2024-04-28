# LDAP Account Tools

## Installation

See [Installation Document](doc/Installation.md).

## Usage

`ldap-account <subcommand>`.

Subcommands:

* `chsh` Change login shell in LDAP
* `config` Show config
* `groupadd` Add a group to LDAP
* `groupdel` Delete a group from LDAP
* `groupmod` Modify a group in LDAP
* `help` Describe available commands or one specific command
* `passwd` Change password in LDAP
* `useradd` Add an user to LDAP
* `userdel` Delete an user from LDAP
* `userlock` Lock/unlock an user from LDAP
* `usermod` Modify an user in LDAP

See `ldap-account help` for their option and more info.

## Test

```bash
bundle exec rake
docker-compose up --build --force-recreate --abort-on-container-exit
```
