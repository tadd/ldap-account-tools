# frozen_string_literal: true

require 'highline'
require 'thor'
require_relative '../util/lock'
require_relative '../util/error'

module LdapAccountManage
  module Chsh
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

    def interactive_chsh(username, options, injector, config)
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
    desc 'chsh [options] [USER]', 'change shell'
    method_option :shell, type: :string,
      aliases: [:s],
      banner: 'SHELL',
      desc: 'Login shell'
    def chsh(username = nil)
      Chsh.interactive_chsh(username, options, @injector, @config)
    end
  end
end
