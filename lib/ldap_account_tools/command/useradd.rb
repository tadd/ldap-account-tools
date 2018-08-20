# frozen_string_literal: true

require 'highline'
require_relative '../util/lock'
require_relative '../util/error'

module LdapAccountManage
  module UserAdd
    module_function

    USERADD_LOCKFILE = 'useradd.lock'

    def _useradd(username, userdata, injector)
      password_hash = '{CRYPT}' + injector.cracklib.crypt_hash(userdata[:password])
      gecos = userdata[:displayname]

      injector.ldap.useradd(
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
        mail: userdata[:mail],
        preferredLanguage: userdata[:lang],
        telephoneNumber: userdata[:phonenumber],
        loginShell: userdata[:shell],
        uidNumber: userdata[:uidnumber],
        gidNumber: userdata[:gidnumber],
        homeDirectory: userdata[:homedir],
        gecos: gecos
      )

      injector.ldap.groupadd(
        objectClass: %w[
          posixGroup
        ],
        cn: username,
        gidNumber: userdata[:gidnumber],
        memberUid: username
      )
    end

    def before_useradd(username, _userdata, ldap)
      if ldap.user_exists?(username)
        raise Util::ToolOperationError, format('already user exists: %<user>s', user: username)
      end
    end

    def after_useradd(username, userdata, injector, config)
      Util.lockfile(config, USERADD_LOCKFILE) do
        if userdata[:uidnumber].nil?
          userdata[:uidnumber] = injector.ldap.next_uidnumber.to_s
        end
        if userdata[:gidnumber].nil?
          userdata[:gidnumber] = userdata[:uidnumber]
        end

        _useradd(username, userdata, injector)
      end
    end

    def useradd(_username, _userdata, _injector, _config)
      # before_useradd(username, userdata)

      raise Util::ToolOperationError, 'not implemented'

      # after_useradd(username, userdata, ldap, config)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    def interactive_useradd(username, options, injector, config)
      before_useradd(username, options, injector.ldap)

      userdata = {}
      cli = HighLine.new

      userdata[:familyname] =
        if !options[:familyname].nil?
          options[:familyname]
        else
          cli.ask('Family name: ').downcase
        end

      userdata[:givenname] =
        if !options[:givenname].nil?
          options[:givenname]
        else
          cli.ask('Given name: ').downcase
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
          mail = cli.ask(format('Mail address [%<default>s]: ', default: mail_default)) do |q|
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
          lang = cli.ask(format('Preferred language [%<lang>s]: ', lang: ENV['LANG']))
          if lang == ''
            ENV['LANG']
          else
            lang
          end
        end

      userdata[:phonenumber] =
        if !options[:phonenumber].nil?
          options[:phonenumber]
        else
          phone = cli.ask('Phone number []: ') do |q|
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
          shell = cli.ask('Login shell [/bin/bash]: ')
          if shell == ''
            '/bin/bash'
          else
            shell
          end
        end

      userdata[:homedir] =
        if !options[:homedir].nil?
          options[:homedir]
        else
          format('/home/%<user>s', user: username)
        end

      userdata[:password] =
        if !options[:password].nil?
          options[:password]
        else
          loop do
            password = cli.ask('Enter your password: ') do |q|
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

            repassword = cli.ask('Confirm your password: ') do |q|
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

      after_useradd(username, userdata, injector, config)

      cli.say(cli.color('Success to create your account.', :green))
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
  end

  module SubCommand
    def command_useradd(username)
      if options[:interactive]
        UserAdd.interactive_useradd(username, options, @injector, @config)
      else
        UserAdd.useradd(username, options, @injector, @config)
      end
    end
  end
end
