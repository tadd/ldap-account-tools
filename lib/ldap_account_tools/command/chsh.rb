# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/base'
require_relative '../util/error'

module LdapAccountManage
  module Chsh
    module_function

    def chsh(username, _options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      shell_default = '/bin/bash'
      shell = cli.ask("Login shell [#{shell_default}]: ")
      if shell == ''
        shell = shell_default
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

    def runuser_chsh(_options, injector, _config)
      cli = HighLine.new

      username = injector.runenv.run_user
      password = cli.ask('Current password: ') do |q|
        q.echo = '*'
      end

      ldap = injector.ldap.userbind_ldap(username, password)

      shell_default = '/bin/bash'
      shell = cli.ask("Login shell [#{shell_default}]: ")
      if shell == ''
        shell = shell_default
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
  end

  class Command
    desc 'chsh [USER]', 'change login shell in LDAP'
    def chsh(username = nil)
      if username.nil?
        Chsh.runuser_chsh(options, @injector, @config)
      else
        Chsh.chsh(username, options, @injector, @config)
      end
    end
  end
end
