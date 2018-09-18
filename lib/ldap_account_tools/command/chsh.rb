# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/base'
require_relative '../util/error'

module LdapAccountManage
  module Chsh
    module_function

    def _chsh(username, cli:, injector:, ldap:, options:)
      shell =
        if !options[:shell].nil?
          options[:shell]
        else
          shell_default = '/bin/bash'
          ask_shell = cli.ask("Login shell [#{shell_default}]: ")

          if ask_shell == ''
            shell_default
          else
            ask_shell
          end
        end

      injector.lock.account_modify_lock do
        ldap.usermod(
          username,
          replace: {
            loginShell: shell,
          },
        )
      end
    end

    def chsh(username, options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      cli = HighLine.new

      _chsh(
        username,
        cli: cli,
        ldap: ldap,
        injector: injector,
        options: options,
      )
    end

    def runuser_chsh(options, injector, _config)
      cli = HighLine.new

      username = injector.runenv.run_user
      password = cli.ask('Current password: ') do |q|
        q.echo = '*'
      end

      ldap = injector.ldap.userbind_ldap(username, password)

      _chsh(
        username,
        cli: cli,
        ldap: ldap,
        injector: injector,
        options: options,
      )
    end
  end

  class Command
    desc 'chsh [options] [USER]', 'change login shell in LDAP'
    method_option :shell, type: :string,
      banner: 'SHELL',
      desc: 'New login shell'
    def chsh(username = nil)
      if username.nil?
        Chsh.runuser_chsh(options, @injector, @config)
      else
        Chsh.chsh(username, options, @injector, @config)
      end
    end
  end
end
