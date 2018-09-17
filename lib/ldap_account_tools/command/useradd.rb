# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/error'
require_relative '../util/account'
require_relative '../injector/ldap'

module LdapAccountManage
  module UserAdd
    module_function

    def _useradd(username, userdata, ldap, injector)
      password_hash = '{CRYPT}' + injector.cracklib.crypt_hash(userdata[:password])
      gecos = userdata[:displayname] + ',,,,' + userdata[:description]

      if userdata[:phonenumber] == ''
        userdata[:phonenumber] = Util::DEFAULT_PHONENUMBER
      end

      ldap.useradd(
        objectClass: %w[
          inetOrgPerson
          posixAccount
          shadowAccount
        ],
        cn: username,
        uid: username,
        userPassword: password_hash,
        sn: userdata[:familyname],
        givenName: userdata[:givenname],
        displayName: userdata[:displayname],
        description: userdata[:desc],
        mail: userdata[:mail],
        preferredLanguage: userdata[:lang],
        telephoneNumber: userdata[:phonenumber],
        loginShell: userdata[:shell],
        uidNumber: userdata[:uidnumber],
        gidNumber: userdata[:gidnumber],
        homeDirectory: userdata[:homedir],
        gecos: gecos
      )

      ldap.groupadd(
        objectClass: %w[
          posixGroup
        ],
        cn: username,
        gidNumber: userdata[:gidnumber],
        description: "The primary group of #{username}",
        memberUid: username
      )
    end

    def before_useradd(username, userdata, ldap, injector)
      if ldap.user_exists_by_name?(username)
        raise Util::ToolOperationError, "already user exists: #{username}"
      end

      Util.validate_userdata(
        userdata,
        ldap: ldap, injector: injector
      )
    end

    def after_useradd(username, userdata, ldap, injector)
      injector.lock.account_modify_lock do
        if userdata[:uidnumber].nil?
          userdata[:uidnumber] = ldap.next_uidnumber.to_s
        end
        if userdata[:gidnumber].nil?
          userdata[:gidnumber] = userdata[:uidnumber]
        end

        _useradd(username, userdata, ldap, injector)
      end
    end

    def get_default_displayname(userdata)
      format(
        '%<given>s %<family>s',
        given: userdata[:givenname].capitalize,
        family: userdata[:familyname].capitalize
      )
    end

    def get_default_mail(username, config)
      if !config['common']['mailhost'].nil?
        format(
          '%<user>s@%<host>s',
          user: username,
          host: config['common']['mailhost']
        )
      else
        ''
      end
    end

    def useradd(username, options, injector, config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      before_useradd(username, options, ldap, injector)

      cli = HighLine.new

      userdata = {}

      unless options[:uidnumber].nil?
        userdata[:uidnumber] = options[:uidnumber]
      end

      userdata[:familyname] =
        if !options[:familyname].nil?
          options[:familyname]
        else
          raise Util::ToolOperationError, 'Must specify any family name'
        end

      userdata[:givenname] =
        if !options[:givenname].nil?
          options[:givenname]
        else
          raise Util::ToolOperationError, 'Must specify any given name'
        end

      userdata[:displayname] =
        if !options[:displayname].nil?
          options[:displayname]
        else
          get_default_displayname(userdata)
        end

      userdata[:desc] =
        if !options[:desc].nil?
          options[:desc]
        else
          'No description.'
        end

      userdata[:mail] =
        if !options[:mail].nil?
          options[:mail]
        else
          get_default_mail(username, config)
        end

      userdata[:lang] =
        if !options[:lang].nil?
          options[:lang]
        else
          injector.runenv.lang
        end

      userdata[:phonenumber] =
        if !options[:phonenumber].nil?
          options[:phonenumber]
        else
          ''
        end

      userdata[:shell] =
        if !options[:shell].nil?
          options[:shell]
        else
          '/bin/bash'
        end

      userdata[:homedir] =
        if !options[:homedir].nil?
          options[:homedir]
        else
          "/home/#{username}"
        end

      userdata[:password] =
        if !options[:password].nil?
          options[:password]
        else
          ask_password(cli, injector, max_count: config['general']['password_retry'])
        end

      after_useradd(username, userdata, ldap, injector)

      cli.say(cli.color('Success to create an account', :green) + ': ' + cli.color(username, :blue))
    end

    def ask_message(name, default: nil)
      cap_name = name.capitalize
      if default.nil?
        "#{cap_name}: "
      else
        "#{cap_name} [#{default}]: "
      end
    end

    def interactive_useradd(username, options, injector, config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      before_useradd(username, options, ldap, injector)

      userdata = {}
      cli = HighLine.new

      cli.say('Input user information:')

      cli.indent_level = 1

      userdata[:familyname] =
        if !options[:familyname].nil?
          options[:familyname]
        else
          cli.ask(ask_message('family name')) do |q|
            q.validate = /.+/
          end
            .downcase
        end

      userdata[:givenname] =
        if !options[:givenname].nil?
          options[:givenname]
        else
          cli.ask(ask_message('given name')) do |q|
            q.validate = /.+/
          end
            .downcase
        end

      userdata[:displayname] =
        if !options[:displayname].nil?
          options[:displayname]
        else
          get_default_displayname(userdata)
        end

      userdata[:desc] =
        if !options[:desc].nil?
          options[:desc]
        else
          'No description.'
        end

      userdata[:mail] =
        if !options[:mail].nil?
          options[:mail]
        else
          mail_default = get_default_mail(username, config)
          mail = cli.ask(ask_message('mail address', default: mail_default)) do |q|
            q.validate = Util::VALIDATE_REGEX_MAIL
          end
          if mail == ''
            mail_default
          else
            mail
          end
        end

      userdata[:lang] =
        if !options[:lang].nil?
          options[:lang]
        else
          lang_default = injector.runenv.lang
          lang = cli.ask(ask_message('preferred language', default: lang_default))
          if lang == ''
            lang_default
          else
            lang
          end
        end

      userdata[:phonenumber] =
        if !options[:phonenumber].nil?
          options[:phonenumber]
        else
          phone_default = ''
          phone = cli.ask(ask_message('phone number', default: phone_default)) do |q|
            q.validate = Util::VALIDATE_REGEX_PHONENUMBER
          end
          if phone == ''
            phone_default
          else
            phone
          end
        end

      userdata[:shell] =
        if !options[:shell].nil?
          options[:shell]
        else
          shell_default = '/bin/bash'
          shell = cli.ask(ask_message('login shell', default: shell_default))
          if shell == ''
            shell_default
          else
            shell
          end
        end

      userdata[:homedir] =
        if !options[:homedir].nil?
          options[:homedir]
        else
          "/home/#{username}"
        end

      userdata[:password] =
        if !options[:password].nil?
          options[:password]
        else
          ask_password(cli, injector, max_count: config['general']['password_retry'])
        end

      after_useradd(username, userdata, ldap, injector)

      cli.indent_level = 0

      cli.say(cli.color('Success to create a user', :green) + ': ' + cli.color(username, :blue))
    end
  end

  class Command
    desc 'useradd USER [options]', 'add an user to LDAP'
    method_option :interactive, type: :boolean, default: true,
      desc: 'enable interactive mode'
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
    method_option :group, type: :array,
      banner: 'GROUP ...',
      desc: 'Extra groups'
    method_option :homedir, type: :string,
      banner: 'DIR',
      desc: 'Home directory'
    def useradd(username)
      if options[:interactive]
        UserAdd.interactive_useradd(username, options, @injector, @config)
      else
        UserAdd.useradd(username, options, @injector, @config)
      end
    end
  end
end
