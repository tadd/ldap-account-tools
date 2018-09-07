# frozen_string_literal: true

require 'etc'
require_relative '../config'
require_relative '../util/error'

module LdapAccountManage
  module SubInjector
    class RunEnv
      def initialize(config)
        @superuser_is_readable_user = config['ldap']['root_info']['superuser_is_readable_user']
        @password_file = config['ldap']['root_info']['password_file']

        can_read_password = check_can_read_password(
          @password_file,
          @superuser_is_readable_user
        )
        @run_user = get_run_user(
          config['ldap']['root_info']['uid'],
          can_read_password,
          @superuser_is_readable_user
        )
      end

      def ldap_password
        unless run_user[:is_superuser]
          raise Util::ToolOperationError, 'You are not the administrator.'
        end

        File.read(@password_file).chomp
      end

      attr_reader :run_user

      def uid_by_username(username)
        Etc.getpwnam(username)
      end

      def userinfo_by_uid(uid)
        Etc.getpwuid(uid)
      end

      def lang
        ENV['LANG']
      end

      private

      def check_can_read_password(password_file, superuser_is_readable_user)
        password_stat =
          begin
            File.lstat(password_file)
          rescue Errno::EACCES => err
            return {
              status: false,
              error: err
            }
          rescue Errno::ENOENT => err
            return {
              status: false,
              error: err
            }
          end

        unless password_stat.readable?
          return {
            status: false,
            error: Errno::EACCES.new('Cannot read file')
          }
        end

        unless check_password_file_mode(password_stat, superuser_is_readable_user)
          raise IllegalConfigError, 'password file should not be executable and read by other users'
        end

        {
          status: true
        }
      end

      def get_run_user(superuser_list, can_read_password, superuser_is_readable_user)
        uid = Process::UID.eid

        if superuser_is_readable_user
          return {
            is_superuser: can_read_password[:status],
            uid: uid
          }
        end

        is_superuser = superuser_list.include?(uid)

        if is_superuser && !can_read_password[:status]
          userinfo = userinfo_by_uid(uid)
          raise IllegalConfigError, format(
            '%<username>s is a super user, but cannot read password: %<error>s',
            username: userinfo[:name],
            error: can_read_password[:error].message
          )
        elsif !is_superuser && can_read_password[:status]
          userinfo = userinfo_by_uid(uid)
          raise IllegalConfigError, format(
            '%<username>s is not a super user, but can read password!',
            username: userinfo[:name]
          )
        end

        {
          is_superuser: is_superuser,
          uid: uid
        }
      end

      def check_password_file_mode(stat, superuser_is_readable_user)
        mode = stat.mode

        if mode & 0o007 != 0
          return false
        end

        if mode & 0o111 != 0
          return false
        end

        if superuser_is_readable_user && mode & 0o077 != 0
          return false
        end

        if stat.owned? && mode & 0o070 != 0
          return false
        end

        true
      end
    end
  end
end
