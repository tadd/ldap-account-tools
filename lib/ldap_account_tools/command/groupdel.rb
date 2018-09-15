# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/error'

module LdapAccountManage
  module GroupDel
    module_function

    def groupdel(groupname, _options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      unless ldap.group_exists_by_name?(groupname)
        raise Util::ToolOperationError, "No such a group exists: #{groupname}"
      end

      injector.lock.account_modify_lock do
        ldap.groupdel(groupname)
      end
    end
  end

  class Command
    desc 'groupdel [options] GROUP', 'delete a group from LDAP'
    def groupdel(groupname)
      GroupDel.groupdel(groupname, options, @injector, @config)
    end
  end
end
