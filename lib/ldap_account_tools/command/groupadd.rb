# frozen_string_literal: true

require 'highline'
require 'thor'
require_relative '../util/lock'
require_relative '../util/error'

module LdapAccountManage
  module GroupAdd
    module_function

    GROUPADD_LOCKFILE = 'groupadd.lock'

    def _groupadd(groupname, groupdata, injector)
      injector.ldap.groupadd(
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
      if ldap.group_exists?(groupname)
        raise Util::ToolOperationError, "already group exists: #{groupname}"
      end

      unless groupdata[:gidnumber].nil?
        if ldap.group_exists_by_gid?(groupdata[:gidnumber])
          raise Util::ToolOperationError, "GID number #{groupdata[:gidnumber]} is already used"
        end
      end
    end

    def after_groupadd(groupname, groupdata, injector, config)
      Util.lockfile(config, GROUPADD_LOCKFILE) do
        if groupdata[:gidnumber].nil?
          groupdata[:gidnumber] = injector.ldap.next_gidnumber.to_s
        end

        _groupadd(groupname, groupdata, injector)
      end
    end

    def groupadd(groupname, options, injector, config)
      before_groupadd(groupname, options, injector.ldap)

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

      after_groupadd(groupname, groupdata, injector, config)

      cli.say(cli.color('Success to create a group', :green) + ': ' + cli.color(groupname, :blue))
    end

    def interactive_groupadd(groupname, options, injector, config)
      before_groupadd(groupname, options, injector.ldap)

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

      after_groupadd(groupname, groupdata, injector, config)

      cli.say(cli.color('Success to create a group', :green) + ': ' + cli.color(groupname, :blue))
    end
  end

  class Command
    desc 'groupadd [options] GROUP', 'add a group to LDAP'
    method_option :gidnumber, type: :string,
      banner: 'NUM',
      desc: 'GID'
    method_option :desc, type: :string,
      banner: 'TEXT',
      desc: 'Description'
    method_option :member, type: :string,
      banner: 'UID,UID,...',
      desc: 'Member UIDs'
    def groupadd(groupname)
      if options[:interactive]
        GroupAdd.interactive_groupadd(groupname, options, @injector, @config)
      else
        GroupAdd.groupadd(groupname, options, @injector, @config)
      end
    end
  end
end