# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/error'

module LdapAccountManage
  module UserMod
    module_function

    def usermod(username, options, injector, _config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      unless ldap.user_exists_by_name?(username)
        raise Util::ToolOperationError, "No such an user exists: #{username}"
      end

      userdata = {}

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
          replace: groupdata
        )
      end
    end
  end

  class Command
    desc 'usermod USER [options]', 'modify an user in LDAP'
    method_option :uidnumber, type: :numeric,
      banner: 'NUM',
      desc: 'UID'
    method_option :gidnumber, type: :numeric,
      banner: 'NUM',
      desc: 'GID'
    method_option :familyname, type: :string,
      banner: 'NAME',
      desc: 'Family Name (lower case)'
    method_option :givenname, type: :string,
      banner: 'NAME',
      desc: 'Given Name (lower case)'
    method_option :displayname, type: :string,
      banner: 'NAME',
      desc: 'Display Name (usually, given by full name)'
    method_option :desc, type: :string,
      banner: 'TEXT',
      desc: 'Description'
    method_option :password, type: :string,
      banner: 'PASSWORD',
      desc: 'Password (normally, you should input by tty)'
    method_option :mail, type: :string,
      banner: 'MAIL',
      desc: 'E-mail address'
    method_option :lang, type: :string,
      banner: 'LANG',
      desc: 'Preferred language'
    method_option :phonenumber, type: :string,
      banner: 'PHONE',
      desc: 'Telephone number'
    method_option :shell, type: :string,
      banner: 'SHELL',
      desc: 'Login shell'
    method_option :group, type: :string,
      banner: 'GROUP ...',
      desc: 'Extra groups'
    method_option :append_group, type: :array,
      banner: 'GROUP ...',
      desc: 'Additional extra groups'
    method_option :homedir, type: :string,
      banner: 'DIR',
      desc: 'Home directory'
    def usermod(username)
      UserMod.usermod(username, options, @injector, @config)
    end
  end
end
