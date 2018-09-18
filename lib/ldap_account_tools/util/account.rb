# frozen_string_literal: true

require_relative '../util/error'

module LdapAccountManage
  module Util
    VALIDATE_REGEX_MAIL = /^(|\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z)$/i
    VALIDATE_REGEX_PHONENUMBER = /^(|\+?[0-9]{6}[0-9]*)$/

    DEFAULT_PHONENUMBER = '00000000000'

    module_function

    def validate_userdata(userdata, ldap:, injector:)
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
        if userdata[:familyname].empty?
          raise Util::ToolOperationError, 'Family name must be not empty.'
        end

        unless userdata[:familyname].downcase == userdata[:familyname]
          raise Util::ToolOperationError, 'Family name must be given by lowercase.'
        end
      end

      unless userdata[:givenname].nil?
        if userdata[:givenname].empty?
          raise Util::ToolOperationError, 'Given name must be not empty.'
        end

        unless userdata[:givenname].downcase == userdata[:givenname]
          raise Util::ToolOperationError, 'Given name must be given by lowercase.'
        end
      end

      unless userdata[:mail].nil?
        unless userdata[:mail] =~ VALIDATE_REGEX_MAIL
          raise Util::ToolOperationError, 'Mail format is illegal.'
        end
      end

      unless userdata[:phonenumber].nil?
        unless userdata[:phonenumber] =~ VALIDATE_REGEX_PHONENUMBER
          raise Util::ToolOperationError, 'Phone number format is illegal.'
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

    def ask_password(cli, injector:, max_count: 3)
      count = max_count
      password = nil
      loop do
        count -= 1
        if count < 0
          raise Util::ToolOperationError, 'Over retry count for password input.'
        end

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

        repassword = cli.ask('Retype the password: ') do |q|
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

    def ldap_password_hash(password, injector:)
      "{CRYPT}#{injector.cracklib.crypt_hash(password)}"
    end
  end
end
