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

ldap-account useradd --no-interactive \
  --password='Very-strength.passW0rd' \
  --familyname='test' --givenname='user' \
  testuser

ldap-account groupadd testgroup
