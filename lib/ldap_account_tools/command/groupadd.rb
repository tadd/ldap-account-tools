# frozen_string_literal: true

require 'highline'
require 'thor'
require_relative '../util/lock'
require_relative '../util/error'

module LdapAccountManage
  module GroupAdd
  end

  class Command
    desc 'groupadd [options] GROUP', 'add a group to LDAP'
    method_option :gid, type: :string,
      banner: 'NUM',
      desc: 'GID'
    method_option :desc, type: :string,
      banner: 'TEXT',
      desc: 'Description'
    def groupadd(groupname)
      if options[:interactive]
        GroupAdd.interactive_groupadd(groupname, options, @injector, @config)
      else
        GroupAdd.groupadd(groupname, options, @injector, @config)
      end
    end
  end
end
