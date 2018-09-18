# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/base'
require_relative '../util/error'

module LdapAccountManage
  module Passwd
    module_function

    def passwd(username, _options, injector, config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      new_password = Util.ask_password(
        cli,
        injector: injector,
        max_count: config['general']['password_retry'],
      )
      injector.lock.account_modify_lock do
        ldap.usermod(
          username,
          replace: {
            userPassword: Util.ldap_password_hash(new_password, injector: injector),
          },
        )
      end
    end

    def runuser_passwd(_options, injector, config)
      cli = HighLine.new

      username = injector.runenv.run_user
      password = cli.ask('Current password: ') do |q|
        q.echo = '*'
      end

      ldap = injector.ldap.userbind_ldap(username, password)

      new_password = Util.ask_password(
        cli,
        injector: injector,
        max_count: config['general']['password_retry'],
      )
      injector.lock.account_modify_lock do
        ldap.usermod(
          username,
          replace: {
            userPassword: Util.ldap_password_hash(new_password, injector: injector),
          },
        )
      end
    end
  end

  class Command
    desc 'passwd [USER]', 'change password in LDAP'
    def passwd(username = nil)
      if username.nil?
        Passwd.runuser_passwd(options, @injector, @config)
      else
        Passwd.passwd(username, options, @injector, @config)
      end
    end
  end
end
