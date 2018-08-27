# frozen_string_literal: true

require 'net-ldap'
require_relative '../config'

module LdapAccountManage
  module SubInjector
    class LdapError < StandardError; end

    class LdapAccount
      def initialize(config, runenv_injector) # rubocop:disable Metrics/AbcSize
        @uid_start = config['general']['uid_start']

        auth_method = config['ldap']['root_info']['auth_method']
        auth_info =
          if auth_method == 'simple'
            {
              method: :simple,
              username: config['ldap']['root_info']['rootbn'],
              password: runenv_injector.ldap_password
            }
          else
            raise IllegalConfigError, "'#{auth_method}'' is not supported method"
          end

        @ldap = Net::LDAP.new(
          host: config['ldap']['host'],
          port: config['ldap']['port'],
          auth: auth_info
        )

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

        @user_filter = Net::LDAP::Filter.eq('objectClass', 'posixAccount')
        @group_filter = Net::LDAP::Filter.eq('objectClass', 'posixGroup')
      end

      attr_reader :userbase
      attr_reader :groupbase

      attr_reader :user_filter
      attr_reader :group_filter

      def report_error(result)
        raise LdapError, format(
          '%<title>s: %<detail>s',
          title: result.message,
          detail: result.error_message
        )
      end

      def ldap_add(options)
        result = @ldap.add(options)
        if result
          result
        else
          report_error(@ldap.get_operation_result)
        end
      end

      def ldap_search(options, &block)
        result = @ldap.search(options, &block)
        if result
          result
        else
          report_error(@ldap.get_operation_result)
        end
      end

      def user_exists?(username)
        result = ldap_search(
          base: userbase,
          filter: user_filter.&(Net::LDAP::Filter.eq('uid', username)),
          attributes: %w[
            cn
          ]
        )
        result.size.positive?
      end

      def user_exists_by_uid?(uid)
        result = ldap_search(
          base: userbase,
          filter: user_filter.&(Net::LDAP::Filter.eq('uidNumber', uid)),
          attributes: %w[
            cn
          ]
        )
        result.size.positive?
      end

      def next_uidnumber
        uid_numbers = Hash.new(false)
        ldap_search(
          base: userbase,
          filter: user_filter,
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

      def group_exists?(groupname)
        result = ldap_search(
          base: groupbase,
          filter: group_filter.&(Net::LDAP::Filter.eq('cn', groupname)),
          attributes: %w[
            cn
          ]
        )
        result.size.positive?
      end

      def group_exists_by_uid?(gid)
        result = ldap_search(
          base: groupbase,
          filter: group_filter.&(Net::LDAP::Filter.eq('gidNumber', gid)),
          attributes: %w[
            cn
          ]
        )
        result.size.positive?
      end

      def next_gidnumber
        gid_numbers = Hash.new(false)
        ldap_search(
          base: groupbase,
          filter: group_filter,
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
        dn = format(
          'cn=%<cn>s,%<userbase>s',
          cn: attrs[:cn],
          userbase: @userbase
        )
        ldap_add(
          dn: dn,
          attributes: attrs
        )
      end

      def groupadd(attrs)
        dn = format(
          'cn=%<cn>s,%<groupbase>s',
          cn: attrs[:cn],
          groupbase: @groupbase
        )
        ldap_add(
          dn: dn,
          attributes: attrs
        )
      end
    end
  end
end
