# Installation

1. Clone the tools:

    ```bash
    sudo git clone \
      https://github.com/mizunashi-mana/ldap-account-tools.git \
      /opt/ldap-account-tools # install on `/opt/ldap-account-tools` directory
    ```

2. Install requirement packages:

    ```bash
    cd /opt/ldap-account-tools
    sudo bundle install --deployment --without development test
    sudo bundle binstub ldap-account-tools # create `bin/ldap-account` script
    ```
3. Create requirement directories:

    ```bash
    sudo mkdir -p \
      /etc/ldap-account-tools/private \
      /var/lib/ldap-account-tools/{data,cache} \
      /var/lock/ldap-account-tools
    sudo touch /etc/ldap-account-tools/private/ldap_password
    sudo chmod 0400 /etc/ldap-account-tools/private/ldap_password
    ```

4. Create custom proxy script:

    ```bash
    $ sudo sh -c 'cat > /usr/local/bin/ldap-account'
    #!/bin/sh

    exec /opt/ldap-account-tools/bin/ldap-account $*
    $ sudo chmod +x /usr/local/bin/ldap-account
    $ ldap-account help # for checking
    ```

5. Place config

    ```bash
    sudo ldap-account config --output /etc/ldap-account-tools/config.yaml
    ```
