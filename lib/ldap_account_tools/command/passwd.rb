# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/base'
require_relative '../util/error'

module LdapAccountManage
  module Passwd
    module_function

    def _passwd(username, cli:, ldap:, injector:, config:, options:)
      new_password =
        if !options[:password].nil?
          options[:password]
        else
          Util.ask_password(
            cli,
            injector: injector,
            max_count: config['general']['password_retry'],
          )
        end
      injector.lock.account_modify_lock do
        ldap.usermod(
          username,
          replace: {
            userPassword: Util.ldap_password_hash(
              new_password,
              injector: injector,
            ),
          },
        )
      end
    end

    def passwd(username, options, injector, config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      cli = HighLine.new

      _passwd(
        username,
        cli: cli,
        ldap: ldap,
        options: options,
        injector: injector,
        config: config,
      )
    end

    def runuser_passwd(options, injector, config)
      cli = HighLine.new

      username = injector.runenv.run_user
      password = cli.ask('Current password: ') do |q|
        q.echo = '*'
      end

      ldap = injector.ldap.userbind_ldap(username, password)

      _passwd(
        username,
        cli: cli,
        ldap: ldap,
        options: options,
        injector: injector,
        config: config,
      )
    end
  end

  class Command
    desc 'passwd [options] [USER]', 'change password in LDAP'
    method_option :password, type: :string,
      banner: 'PASSWORD',
      desc: 'New password (normally, you should input by tty)'
    def passwd(username = nil)
      if username.nil?
        Passwd.runuser_passwd(options, @injector, @config)
      else
        Passwd.passwd(username, options, @injector, @config)
      end
    end
  end
end
