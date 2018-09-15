#!/usr/bin/env bash

set -x
set -euo pipefail
shopt -s nullglob

PREINSTALL_DIR="/root/ldap-account-tools"
INSTALL_DIR="/opt/ldap-account-tools"

mkdir -p $INSTALL_DIR
git clone $PREINSTALL_DIR/.git $INSTALL_DIR
git -C $PREINSTALL_DIR ls-files \
  | xargs -I{} cp $PREINSTALL_DIR/{} $INSTALL_DIR/{}
cd $INSTALL_DIR

cp -r ${BUNDLE_CACHE_DIR}/vendor vendor

bundle install --local --deployment --without development test
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


# delete groups
ldap-account groupdel testgroup


# test show
slapcat
