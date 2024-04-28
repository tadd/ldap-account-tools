# LDAP Account Tools

## Installation

See [Installation Document](doc/Installation.md).

## Usage

`ldap-account <subcommand>`.

Subcommands:

* `chsh [options] [USER]`
* `config [option]`
* `groupadd GROUP [options]`
* `groupdel [options] GROUP`
* `groupmod GROUP [options]`
* `help [COMMAND]`
* `passwd [options] [USER]`
* `useradd USER [options]`
* `userdel [options] USER`
* `userlock [options] USER`
* `usermod USER [options]`

See `ldap-account help` for their option and more information.

## Test

```bash
bundle exec rake
docker-compose up --build --force-recreate --abort-on-container-exit
```
