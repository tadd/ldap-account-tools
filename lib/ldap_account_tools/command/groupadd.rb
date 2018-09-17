# frozen_string_literal: true

require 'highline'
require 'thor'
require_relative '../util/error'

module LdapAccountManage
  module GroupAdd
    module_function

    def _groupadd(groupname, groupdata, ldap)
      ldap.groupadd(
        objectClass: %w[
          posixGroup
        ],
        cn: groupname,
        gidNumber: groupdata[:gidnumber],
        description: groupdata[:description],
        memberUid: groupdata[:memberUid]
      )
    end

    def before_groupadd(groupname, groupdata, ldap)
      if ldap.group_exists_by_name?(groupname)
        raise Util::ToolOperationError, "Already group exists: #{groupname}"
      end

      unless groupdata[:gidnumber].nil?
        if ldap.group_exists_by_gid?(groupdata[:gidnumber])
          raise Util::ToolOperationError, "GID number #{groupdata[:gidnumber]} is already used"
        end
      end
    end

    def after_groupadd(groupname, groupdata, ldap, injector)
      injector.lock.account_modify_lock do
        if groupdata[:gidnumber].nil?
          groupdata[:gidnumber] = ldap.next_gidnumber.to_s
        end

        _groupadd(groupname, groupdata, ldap)
      end
    end

    def groupadd(groupname, options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      before_groupadd(groupname, options, ldap)

      cli = HighLine.new

      groupdata = {}

      unless options[:gidnumber].nil?
        groupdata[:gidnumber] = options[:gidnumber]
      end

      groupdata[:description] =
        if !options[:desc].nil?
          options[:desc]
        else
          'No description.'
        end

      groupdata[:memberUid] =
        if !options[:member].nil?
          options[:member]
        else
          []
        end

      after_groupadd(groupname, groupdata, ldap, injector)

      cli.say(cli.color('Success to create a group', :green) + ': ' + cli.color(groupname, :blue))
    end

    def interactive_groupadd(groupname, options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      before_groupadd(groupname, options, ldap)

      cli = HighLine.new

      groupdata = {}

      unless options[:gidnumber].nil?
        groupdata[:gidnumber] = options[:gidnumber]
      end

      groupdata[:description] =
        if !options[:desc].nil?
          options[:desc]
        else
          'No description.'
        end

      groupdata[:memberUid] =
        if !options[:member].nil?
          options[:member]
        else
          []
        end

      after_groupadd(groupname, groupdata, ldap, injector)

      cli.say(cli.color('Success to create a group', :green) + ': ' + cli.color(groupname, :blue))
    end
  end

  class Command
    desc 'groupadd GROUP [options]', 'add a group to LDAP'
    method_option :gidnumber, type: :string,
      banner: 'NUM',
      desc: 'GID'
    method_option :desc, type: :string,
      banner: 'TEXT',
      desc: 'Description'
    method_option :member, type: :array,
      banner: 'USER ...',
      desc: 'Member users (can multiply)'
    def groupadd(groupname)
      if options[:interactive]
        GroupAdd.interactive_groupadd(groupname, options, @injector, @config)
      else
        GroupAdd.groupadd(groupname, options, @injector, @config)
      end
    end
  end
end
