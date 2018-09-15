#!/usr/bin/env bash

set -x
set -euo pipefail
shopt -s nullglob

INSTALL_DIR="/root/ldap-account-tools"

git clone $INSTALL_DIR/.git /opt/ldap-account-tools
cd /opt/ldap-account-tools

bundle install --deployment --without development test
bundle binstub ldap-account-tools

/etc/init.d/slapd start

ldap-account help

# create users

ldap-account useradd --no-interactive \
  --password 'Very-strength.passW0rd' \
  --familyname 'test' --givenname 'user' \
  testuser

ldap-account useradd --no-interactive \
  --password 'Very-strength.passW0rd' \
  --familyname 'test_has_info' --givenname 'user' \
  --mail 'testuser_has_info@example.com' \
  --desc 'Test user has some info' \
  testuser_has_info


# create groups

ldap-account groupadd testgroup

ldap-account groupadd \
  testgroup_has_users \
  --desc 'Test group has some members' \
  --member testuser testuser_has_info


# delete users
ldap-account userdel testuser


# test show
slapcat

exec tail -f /var/log/faillog
