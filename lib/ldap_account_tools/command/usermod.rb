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

      unless options[:uidnumber].nil?
        userdata[:uidnumber] = options[:uidnumber]
      end

      unless options[:familyname].nil?
        userdata[:familyname] = options[:familyname]
      end

      unless userdata[:givenname].nil?
        userdata[:givenname] = options[:givenname]
      end

      unless userdata[:displayname].nil?
        userdata[:displayname] = options[:displayname]
      end

      unless userdata[:desc].nil?
        userdata[:desc] = options[:desc]
      end

      unless userdata[:mail].nil?
        userdata[:mail] = options[:mail]
      end

      unless userdata[:lang].nil?
        userdata[:lang] = options[:lang]
      end

      unless userdata[:phonenumber].nil?
        userdata[:phonenumber] = options[:phonenumber]
      end

      unless userdata[:shell].nil?
        userdata[:shell] = options[:shell]
      end

      unless userdata[:homedir].nil?
        userdata[:homedir] = options[:homedir]
      end

      unless userdata[:password].nil?
        userdata[:password] = options[:password]
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
