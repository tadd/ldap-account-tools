# frozen_string_literal: true

require 'net-ldap'
require_relative '../config'

module LdapAccountManage
  class LdapError < StandardError
    def initialize(result)
      type = result.message
      detail = result.error_message
      super("#{type}: #{detail}")
      @type = type
      @detail = detail
    end

    attr_reader :type
    attr_reader :detail
  end

  module SubInjector
    class NetLdapWrapper
      def initialize(options)
        @ldap = Net::LDAP.new(options)
      end

      def from_result(result)
        if result
          {
            status: true,
            content: result,
          }
        else
          {
            status: false,
            error: LdapError.new(@ldap.get_operation_result),
          }
        end
      end

      def normalized_attributes(attrs)
        result = {}

        attrs.each do |k, v|
          unless v.is_a?(Array) && v.empty?
            result[k] = v
          end
        end

        result
      end

      def add(dn:, attributes:)
        from_result(
          @ldap.add(
            dn: dn,
            attributes: normalized_attributes(attributes),
          ),
        )
      end

      def delete(dn:)
        from_result(
          @ldap.delete(
            dn: dn,
          ),
        )
      end

      def normalized_operations(operations)
        result = []

        operations.each do |operation_type, operation_vals|
          if operation_vals.is_a?(Array)
            operation_vals.each do |operation_val|
              result.push([operation_type, operation_val, nil])
            end
          else
            operation_vals.each do |operation_key, operation_val|
              result.push([operation_type, operation_key, operation_val])
            end
          end
        end

        result
      end

      def modify(dn:, operations:)
        from_result(
          @ldap.modify(
            dn: dn,
            operations: normalized_operations(operations),
          ),
        )
      end

      def search(base:, filter:, attributes:, &block)
        from_result(
          @ldap.search(
            base: base,
            filter: filter,
            attributes: attributes,
            &block
          ),
        )
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
          raise result[:error]
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
          ],
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
          ],
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
          ],
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
          ],
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
            attributes: attrs,
          )
        end
      end

      def groupadd(attrs)
        from_result do
          @ldap.add(
            dn: "cn=#{attrs[:cn]},#{groupbase}",
            attributes: attrs,
          )
        end
      end

      def userdel(name)
        from_result do
          @ldap.delete(
            dn: "cn=#{name},#{userbase}",
          )
        end
      end

      def groupdel(name)
        from_result do
          @ldap.delete(
            dn: "cn=#{name},#{groupbase}",
          )
        end
      end

      def groups_from_member(username, &block)
        group_search(
          filter: Net::LDAP::Filter.eq('memberUid', username),
          attributes: %w[
            cn
            gidNumber
            memberUid
          ],
          &block
        )
      end

      def member_in_group(groupname)
        entries = group_search(
          filter: Net::LDAP::Filter.eq('cn', groupname),
          attributes: %w[
            cn
            memberUid
          ],
        )

        if entries.empty?
          raise LdapError, "No such a group: #{groupname}"
        elsif entries[0].attribute_names.member?(:memberuid)
          entries[0].memberuid
        else
          []
        end
      end

      def usermod(name, operations)
        from_result do
          @ldap.modify(
            dn: "cn=#{name},#{userbase}",
            operations: operations,
          )
        end
      end

      def groupmod(name, operations)
        from_result do
          @ldap.modify(
            dn: "cn=#{name},#{groupbase}",
            operations: operations,
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
            "ou=people,#{config['ldap']['base']}"
          end
        @groupbase =
          if !config['ldap']['groupbase'].nil?
            config['ldap']['groupbase']
          else
            "ou=group,#{config['ldap']['base']}"
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
              tls_options: tls_options,
            }
          when 'start_tls' then
            {
              method: :start_tls,
              tls_options: tls_options,
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
              method: :anonymous,
            }
          elsif auth_method == 'simple'
            {
              method: :simple,
              username: @superuser_auth_info['dn'],
              password: runenv_injector.ldap_password,
            }
          else
            raise LdapError, "Unsupported auth method: #{auth_method}"
          end

        ldap = @ldap.new(
          host: ldap_host,
          port: ldap_port,
          auth: auth_info,
          encryption: ldap_encryption,
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
              method: :anonymous,
            }
          elsif auth_method == 'simple'
            {
              method: :simple,
              username: "cn=#{username},#{@userbase}",
              password: password,
            }
          else
            raise LdapError, "Unsupported auth method: #{auth_method}"
          end

        ldap = @ldap.new(
          host: ldap_host,
          port: ldap_port,
          auth: auth_info,
        )

        LdapInstanceWrapper.new(
          ldap,
          uid_start: @uid_start,
          gid_start: @gid_start,
          userbase: @userbase,
          groupbase: @groupbase,
        )
      end
    end
  end
end
