# frozen_string_literal: true

require 'net-ldap'
require_relative '../config'

module LdapAccountManage
  module SubInjector
    class LdapError < StandardError; end

    class NetLdapWrapper
      def initialize(options)
        @ldap = Net::LDAP.new(options)
      end

      def error_report_by_result(result)
        "#{result.message}: #{result.error_message}"
      end

      def add(options)
        result = @ldap.add(options)
        if result
          {
            status: true,
            content: result
          }
        else
          {
            status: false,
            message: error_report_by_result(@ldap.get_operation_result)
          }
        end
      end

      def modify(options)
        result = @ldap.modify(options)
        if result
          {
            status: true,
            content: result
          }
        else
          {
            status: false,
            message: error_report_by_result(@ldap.get_operation_result)
          }
        end
      end

      def search(options, &block)
        result = @ldap.search(options, &block)
        if result
          {
            status: true,
            content: result
          }
        else
          {
            status: false,
            message: error_report_by_result(@ldap.get_operation_result)
          }
        end
      end
    end

    class LdapInstanceWrapper
      def initialize(
        ldap,
        uid_start:, gid_start:,
        userbase:, groupbase:
      )
        @ldap = ldap

        @uid_start = uid_start
        @gid_start = gid_start

        @userbase = userbase
        @groupbase = groupbase

        @user_filter = Net::LDAP::Filter.eq('objectClass', 'posixAccount')
        @group_filter = Net::LDAP::Filter.eq('objectClass', 'posixGroup')
      end

      attr_reader :uid_start
      attr_reader :gid_start

      attr_reader :userbase
      attr_reader :groupbase

      attr_reader :user_filter
      attr_reader :group_filter

      def from_result
        result = yield
        if result[:status]
          result[:content]
        else
          raise LdapError, result[:message]
        end
      end

      def user_search(filter:, attributes:, &block)
        from_result do
          @ldap.search(
            base: userbase,
            filter: user_filter.&(filter),
            attributes: attributes,
            &block
          )
        end
      end

      def group_search(filter:, attributes:, &block)
        from_result do
          @ldap.search(
            base: groupbase,
            filter: group_filter.&(filter),
            attributes: attributes,
            &block
          )
        end
      end

      def user_exists?(filter)
        result = user_search(
          filter: filter,
          attributes: %w[
            cn
          ]
        )
        result.size.positive?
      end

      def user_exists_by_name?(name)
        user_exists?(Net::LDAP::Filter.eq('uid', name))
      end

      def user_exists_by_uid?(uid)
        user_exists?(Net::LDAP::Filter.eq('uidNumber', uid))
      end

      def group_exists?(filter)
        result = group_search(
          filter: filter,
          attributes: %w[
            cn
          ]
        )
        result.size.positive?
      end

      def group_exists_by_name?(name)
        group_exists?(Net::LDAP::Filter.eq('cn', name))
      end

      def group_exists_by_gid?(gid)
        group_exists?(Net::LDAP::Filter.eq('gidNumber', gid))
      end

      def next_uidnumber
        uid_numbers = Hash.new(false)
        user_search(
          filter: Net::LDAP::Filter.ge('uidNumber', 0),
          attributes: %w[
            uidNumber
          ]
        ) do |entry|
          entry.uidnumber.each do |num|
            uid_numbers[num] = true
          end
        end

        uid = @uid_start
        loop do
          break unless uid_numbers[uid.to_s]
          uid += 1
        end

        uid
      end

      def next_gidnumber
        gid_numbers = Hash.new(false)
        group_search(
          filter: Net::LDAP::Filter.ge('gidNumber', 0),
          attributes: %w[
            gidNumber
          ]
        ) do |entry|
          entry.gidnumber.each do |num|
            gid_numbers[num] = true
          end
        end

        gid = @gid_start
        loop do
          break unless gid_numbers[gid.to_s]
          gid += 1
        end

        gid
      end

      def useradd(attrs)
        from_result do
          @ldap.add(
            dn: "cn=#{attrs[:cn]},#{userbase}",
            attributes: attrs
          )
        end
      end

      def groupadd(attrs)
        from_result do
          @ldap.add(
            dn: "cn=#{attrs[:cn]},#{groupbase}",
            attributes: attrs
          )
        end
      end
    end

    class LdapAccount
      def initialize(config, ldap: nil)
        @ldap =
          if ldap.nil?
            NetLdapWrapper
          else
            ldap
          end

        @uid_start = config['general']['uid_start']
        @gid_start = config['general']['gid_start']

        @userbase =
          if !config['ldap']['userbase'].nil?
            config['ldap']['userbase']
          else
            'ou=people,' + config['ldap']['base']
          end
        @groupbase =
          if !config['ldap']['groupbase'].nil?
            config['ldap']['groupbase']
          else
            'ou=group,' + config['ldap']['base']
          end

        tls_options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
        config['ldap']['tls_options'].each do |k, v|
          tls_options[k.to_sym] = v
        end

        @ldap_host = config['ldap']['host']
        @ldap_port = config['ldap']['port']
        @ldap_encryption =
          case config['ldap']['tls']
          when 'off' then nil
          when 'on' then
            {
              method: :simple_tls,
              tls_options: tls_options
            }
          when 'start_tls' then
            {
              method: :start_tls,
              tls_options: tls_options
            }
          end

        @superuser_auth_info = config['ldap']['root_info']
        @user_auth_info = config['ldap']['user_info']
      end

      attr_reader :ldap_host
      attr_reader :ldap_port
      attr_reader :ldap_encryption

      def superuserbind_ldap(runenv_injector)
        auth_method = @superuser_auth_info['auth_method']
        auth_info =
          if auth_method == 'anonymous'
            {
              method: :anonymous
            }
          elsif auth_method == 'simple'
            {
              method: :simple,
              username: @superuser_auth_info['dn'],
              password: runenv_injector.ldap_password
            }
          else
            raise LdapError, "Unsupported auth method: #{auth_method}"
          end

        ldap = @ldap.new(
          host: ldap_host,
          port: ldap_port,
          auth: auth_info,
          encryption: ldap_encryption
        )

        LdapInstanceWrapper.new(
          ldap,
          uid_start: @uid_start, gid_start: @gid_start,
          userbase: @userbase, groupbase: @groupbase
        )
      end

      def userbind_ldap(username, password)
        auth_method = @user_auth_info['auth_method']
        auth_info =
          if auth_method == 'anonymous'
            {
              method: :anonymous
            }
          elsif auth_method == 'simple'
            {
              method: :simple,
              username: "cn=#{username},#{@userbase}",
              password: password
            }
          else
            raise LdapError, "Unsupported auth method: #{auth_method}"
          end

        ldap = @ldap.new(
          host: ldap_host,
          port: ldap_port,
          auth: auth_info
        )

        LdapInstanceWrapper.new(
          ldap,
          uid_start: @uid_start, gid_start: @gid_start,
          userbase: @userbase, groupbase: @groupbase
        )
      end
    end
  end
end
