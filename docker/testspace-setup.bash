#!/usr/bin/env bash

set -x
set -euo pipefail
shopt -s nullglob

LDAP_PASSWORD="password"

mkdir -p \
  /etc/ldap-account-tools \
  /var/lib/ldap-account-tools/{data,cache} \
  /var/lock/ldap-account-tools

cat > /usr/local/bin/ldap-account <<EOS
#!/bin/sh

exec /opt/ldap-account-tools/bin/ldap-account "\$@"
EOS
chmod +x /usr/local/bin/ldap-account

mkdir -p /etc/ldap-account-tools/private
echo -n "$LDAP_PASSWORD" > /etc/ldap-account-tools/private/ldap_password
chmod 0400 /etc/ldap-account-tools/private/ldap_password

cat > /etc/ldap-account-tools/config.yaml <<EOS
general:
  uid_start: 2000
  gid_start: 30000
common:
  mailhost: localhost
ldap:
  host: localhost
  port: 389
  base: dc=nodomain
  tls: 'off'
  root_info:
    auth_method: simple
    dn: cn=admin,dc=nodomain
    password_file: "/etc/ldap-account-tools/private/ldap_password"
  user_info:
    auth_method: simple
EOS

/etc/init.d/slapd start

mkdir -p /tmp/ldif

cat > /tmp/ldif/changepasswd.ldif <<EOS
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $(slappasswd -s "$LDAP_PASSWORD")
EOS
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/ldif/changepasswd.ldif

cat > /tmp/ldif/acl.ldif <<EOS
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to attrs=userPassword
  by dn="cn=admin,dc=nodomain" write
  by anonymous auth
  by self write
  by * none
-
add: olcAccess
olcAccess: {1}to attrs=shadowLastChange,sn,givenName,displayName,mail,preferredLanguage,telephoneNumber,loginShell,gecos
  by dn="cn=admin,dc=nodomain" write
  by self write
  by * read
-
add: olcAccess
olcAccess: {2}to *
  by dn="cn=admin,dc=nodomain" write
  by * read
EOS
ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/ldif/acl.ldif

cat > /tmp/ldif/add-base-orgs.ldif <<EOS
dn: ou=people,dc=nodomain
changetype: add
objectClass: organizationalUnit
ou: people

dn: ou=group,dc=nodomain
changetype: add
objectClass: organizationalUnit
ou: group
EOS
ldapmodify -x -H ldap://localhost \
  -D 'cn=admin,dc=nodomain' \
  -y /etc/ldap-account-tools/private/ldap_password \
  -f /tmp/ldif/add-base-orgs.ldif

/etc/init.d/slapd stop
