# frozen_string_literal: true

require 'highline'
require 'rubylibcrack'
require_relative '../util/lock'

module LdapAccountManage
  module UserAdd
    module_function

    USERADD_LOCKFILE = 'useradd.lock'

    def crypt_hash(str)
      salt = '$6$' + Array.new(15).map { |_| rand(64) }.pack('C*').tr("\x00-\x3f", 'A-Za-z0-9./')
      str.crypt(salt)
    end

    def _useradd(username, userdata, ldap)
      password_hash = crypt_hash(userdata[:password])
      gecos = userdata[:displayname]

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
        memberUid: [username]
      )
    end

    def before_useradd(username, _userdata)
      if user_exists?(username)
        raise Util.ToolOperationError, 'already user exists: %<user>s'.format(user: username)
      end
    end

    def after_useradd(username, userdata, ldap, config)
      Util.lockfile(config, USERADD_LOCKFILE) do
        if userdata[:uidnumber].nil?
          userdata[:uidnumber] = ldap.next_uidnumber
        end
        if userdata[:gidnumber].nil?
          userdata[:gidnumber] = userdata[:uidnumber]
        end

        _useradd(username, userdata, ldap)
      end
    end

    def useradd(_username, _userdata, _injector, _config)
      # before_useradd(username, userdata)

      raise ToolOperationError, 'not implemented'

      # after_useradd(username, userdata, ldap, config)
    end

    def interactive_useradd(username, userdata, injector, config) # rubocop:disable Metrics/AbcSize
      before_useradd(username, userdata)

      cli = HighLine.new

      if userdata[:familyname].nil?
        userdata[:familyname] = HighLine.new.ask('Family Name: ').downcase
      end

      if userdata[:givenname].nil?
        userdata[:givenname] = HighLine.new.ask('Given Name: ').downcase
      end

      if userdata[:displayname].nil?
        userdata[:displayname] = '%<given> %<family>'.format(
          given: userdata[:givenname].capitalize,
          family: userdata[:familyname].capitalize
        )
      end

      if userdata[:mail].nil?
        userdata[:mail] =
          if config['common']['mailhost'].nil?
            '%<user>s@%<host>s'.format(
              user: username,
              host: config['common']['mailhost']
            )
          else
            HighLine.new.ask('E-Mail []: ') do |q|
              q.validate = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
            end
          end
      end

      if userdata[:lang].nil?
        userdata[:lang] = HighLine.new.ask('Preferred language [%<lang>s]: '.format(ENV['LANG'])) do |q|
          q.default = ENV['LANG']
        end
      end

      loop do
        password = cli.ask('Enter your password: ') do |q|
          q.echo = 'x'
        end
        if password.size <= 11
          cli.say(cli.color('Too small password! Should be >=12 characters', :red))
          next
        end

        check = Cracklib::Password.new(password)
        unless check.strong?
          cli.say(cli.color("Weak password! #{check.message}", :red))
          next
        end

        repassword = cli.ask('Confirm your password: ') do |q|
          q.echo = 'x'
        end
        if password != repassword
          cli.say(cli.color('Password mismatch!', :red))
          next
        end

        userdata[:password] = password
        password = nil # rubocop:disable Lint/UselessAssignment
        repassword = nil # rubocop:disable Lint/UselessAssignment

        break
      end

      after_useradd(username, userdata, injector.ldap, config)
    end
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
