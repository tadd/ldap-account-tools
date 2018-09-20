# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/error'

module LdapAccountManage
  module UserLock
    module_function

    def userlock(username, _options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      unless ldap.user_exists_by_name?(username)
        raise Util::ToolOperationError, "No such an user exists: #{username}"
      end

      injector.lock.account_modify_lock do
        ldap.usermod(
          username,
          replace: {
            pwdAccountLockedTime: '000001010000Z',
          },
        )
      end
    end

    def userunlock(username, _options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      unless ldap.user_exists_by_name?(username)
        raise Util::ToolOperationError, "No such an user exists: #{username}"
      end

      injector.lock.account_modify_lock do
        ldap.usermod(
          username,
          delete: [:pwdAccountLockedTime],
        )
      end
    end
  end

  class Command
    desc 'userlock [options] USER', 'lock/unlock an user from LDAP'
    method_option :unlock, type: :boolean, default: false,
      desc: 'Unlock mode'
    def userlock(username)
      if options[:unlock]
        UserLock.userunlock(username, options, @injector, @config)
      else
        UserLock.userlock(username, options, @injector, @config)
      end
    end
  end
end
