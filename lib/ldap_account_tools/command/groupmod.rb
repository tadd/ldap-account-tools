# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/error'

module LdapAccountManage
  module GroupMod
    module_function

    def groupmod(groupname, options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      unless ldap.group_exists_by_name?(groupname)
        raise Util::ToolOperationError, "No such a group exists: #{groupname}"
      end

      groupdata = {}

      unless options[:gidnumber].nil?
        groupdata[:gidNumber] = options[:gidnumber]
      end

      unless options[:desc].nil?
        groupdata[:description] = options[:desc]
      end

      unless options[:member].nil? && options[:append_member].nil? && options[:delete_member].nil?
        groupdata[:memberUid] = ldap.member_in_group(groupname)

        unless options[:member].nil?
          options[:member].each do |username|
            unless ldap.user_exists_by_name?(username)
              raise Util::ToolOperationError, "No such a user exists: #{username}"
            end
          end
          groupdata[:memberUid] = options[:member]
        end

        unless options[:append_member].nil?
          options[:append_member].each do |username|
            unless ldap.user_exists_by_name?(username)
              raise Util::ToolOperationError, "No such a user exists: #{username}"
            end
          end
          groupdata[:memberUid] += options[:append_member]
        end

        unless options[:delete_member].nil?
          groupdata[:memberUid] -= options[:delete_member]
        end
      end

      injector.lock.account_modify_lock do
        ldap.groupmod(
          groupname,
          replace: groupdata,
        )
      end
    end
  end

  class Command
    desc 'groupmod GROUP [options]', 'modify a group in LDAP'
    method_option :gidnumber, type: :string,
      banner: 'NUM',
      desc: 'GID'
    method_option :desc, type: :string,
      banner: 'TEXT',
      desc: 'Description'
    method_option :member, type: :array,
      banner: 'USER ...',
      desc: 'Member users (can multiply)'
    method_option :delete_member, type: :array,
      banner: 'USER ...',
      desc: 'Member users (can multiply)'
    method_option :append_member, type: :array,
      banner: 'USER ...',
      desc: 'Member users (can multiply)'
    def groupmod(groupname)
      GroupMod.groupmod(groupname, options, @injector, @config)
    end
  end
end
