# frozen_string_literal: true

require 'thor'
require 'highline'
require_relative '../util/lock'
require_relative '../util/error'

module LdapAccountManage
  module UserAdd
    module_function

    USERADD_LOCKFILE = 'useradd.lock'

    def _useradd(username, userdata, ldap, injector)
      password_hash = '{CRYPT}' + injector.cracklib.crypt_hash(userdata[:password])
      gecos = userdata[:displayname] + ',' + userdata[:description]

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
        description: userdata[:description],
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

    def before_useradd(username, userdata, ldap)
      if ldap.user_exists_by_name?(username)
        raise Util::ToolOperationError, "already user exists: #{username}"
      end

      unless userdata[:uidnumber].nil?
        if ldap.user_exists_by_uid?(userdata[:uidnumber])
          raise Util::ToolOperationError, "UID number #{userdata[:uidnumber]} is already used"
        end
      end

      unless userdata[:gidnumber].nil?
        if ldap.group_exists_by_gid?(userdata[:gidnumber])
          raise Util::ToolOperationError, "GID number #{userdata[:gidnumber]} is already used"
        end
      end

      unless userdata[:familyname].nil?
        unless /[[:lower:]]/ =~ userdata[:familyname]
          raise Util::ToolOperationError, 'Family name must be given by lowercase.'
        end
      end

      unless userdata[:givenname].nil?
        unless /[[:lower:]]/ =~ userdata[:givenname]
          raise Util::ToolOperationError, 'Given name must be given by lowercase.'
        end
      end

      unless userdata[:password].nil?
        password = userdata[:password]

        if password.size < 12
          raise Util::ToolOperationError, 'Password should have >=12 characters'
        end

        check = injector.cracklib.check_password(password)
        unless check[:is_strong]
          raise Util::ToolOperationError, "Password is weak: #{check[:message]}"
        end
      end
    end

    def after_useradd(username, userdata, ldap, injector, config)
      Util.lockfile(config, USERADD_LOCKFILE) do
        if userdata[:uidnumber].nil?
          userdata[:uidnumber] = ldap.next_uidnumber.to_s
        end
        if userdata[:gidnumber].nil?
          userdata[:gidnumber] = userdata[:uidnumber]
        end

        _useradd(username, userdata, ldap, injector)
      end
    end

    def ask_password(cli, injector, max_count: 3)
      count = max_count
      password = nil
      loop do
        count -= 1
        if count < 0
          raise Util::ToolOperationError, 'Over retry count for password input.'
        end

        password = cli.ask("\tEnter your password: ") do |q|
          q.echo = '*'
        end
        if password.size <= 11
          cli.say(cli.color('Too small password! Should be >=12 characters', :red))
          next
        end

        check = injector.cracklib.check_password(password)
        unless check[:is_strong]
          cli.say(cli.color("Weak password! #{check[:message]}", :red))
          next
        end

        repassword = cli.ask("\tConfirm your password: ") do |q|
          q.echo = '*'
        end
        if password != repassword
          cli.say(cli.color('Password mismatch!', :red))
          next
        end

        break
      end

      password
    end

    def useradd(username, options, injector, config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      before_useradd(username, options, ldap)

      cli = HighLine.new

      userdata = {}

      unless options[:uidnumber]
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
          format(
            '%<given>s %<family>s',
            given: userdata[:givenname].capitalize,
            family: userdata[:familyname].capitalize
          )
        end

      userdata[:description] =
        if !options[:desc].nil?
          options[:desc]
        else
          'No description.'
        end

      userdata[:mail] =
        if !options[:mail].nil?
          options[:mail]
        elsif !config['common']['mailhost'].nil?
          format(
            '%<user>s@%<host>s',
            user: username,
            host: config['common']['mailhost']
          )
        else
          ''
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
          '00000000000'
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

      after_useradd(username, userdata, ldap, injector, config)

      cli.say(cli.color('Success to create your account.', :green))
    end

    def ask_message(name, default: nil)
      cap_name = name.capitalize
      if default.nil?
        "\t#{cap_name}: "
      else
        "\t#{cap_name} [#{default}]: "
      end
    end

    def interactive_useradd(username, options, injector, config)
      ldap = injector.ldap.superuserbind_ldap(injector.runenv)

      before_useradd(username, options, ldap)

      userdata = {}
      cli = HighLine.new

      cli.say('Input user information:')

      userdata[:familyname] =
        if !options[:familyname].nil?
          options[:familyname]
        else
          cli.ask(ask_message('family name')).downcase
        end

      userdata[:givenname] =
        if !options[:givenname].nil?
          options[:givenname]
        else
          cli.ask(ask_message('given name')).downcase
        end

      userdata[:displayname] =
        if !options[:displayname].nil?
          options[:displayname]
        else
          format(
            '%<given>s %<family>s',
            given: userdata[:givenname].capitalize,
            family: userdata[:familyname].capitalize
          )
        end

      userdata[:description] =
        if !options[:desc].nil?
          options[:desc]
        else
          'No description.'
        end

      userdata[:mail] =
        if !options[:mail].nil?
          options[:mail]
        else
          mail_default =
            if !config['common']['mailhost'].nil?
              format(
                '%<user>s@%<host>s',
                user: username,
                host: config['common']['mailhost']
              )
            else
              ''
            end
          mail = cli.ask(ask_message('mail address', default: mail_default)) do |q|
            q.validate = /(|\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z)/i
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
          phone = cli.ask(ask_message('phone number', default: '')) do |q|
            q.validate = /^(|\+?[0-9]{6}[0-9]*)$/
          end
          if phone == ''
            '00000000000'
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

      after_useradd(username, userdata, ldap, injector, config)

      cli.say(cli.color('Success to create a user', :green) + ': ' + cli.color(username, :blue))
    end
  end

  class Command
    desc 'useradd [options] USER', 'add an user to LDAP'
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
      desc: 'password (normally, you should input by tty)'
    method_option :mail, type: :string,
      banner: 'EMAIL',
      desc: 'email address'
    method_option :lang, type: :string,
      banner: 'LANG',
      desc: 'preferred language'
    method_option :phonenumber, type: :string,
      banner: 'PHONE',
      desc: 'telephone number'
    method_option :shell, type: :string,
      banner: 'SHELL',
      desc: 'login shell'
    method_option :group, type: :string,
      banner: 'GROUP,GROUP,...',
      desc: 'extra groups'
    method_option :homedir, type: :string,
      banner: 'DIR',
      desc: 'home directory'
    def useradd(username)
      if options[:interactive]
        UserAdd.interactive_useradd(username, options, @injector, @config)
      else
        UserAdd.useradd(username, options, @injector, @config)
      end
    end
  end
end
