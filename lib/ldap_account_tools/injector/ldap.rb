# frozen_string_literal: true

require 'net-ldap'

module LdapAccountManage
  module SubInjector
    class LdapError < StandardError; end

    class LdapAccount
      def initialize(config) # rubocop:disable Metrics/AbcSize
        config['ldap']['uri']

        @uid_start = config['general']['uid_start']
        @ldap = Net::LDAP.new(
          host: config['ldap']['host'],
          port: config['ldap']['port']
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
      end

      def user_exists?(username)
        result = @ldap.search(
          base: @userbase,
          filter: Net::LDAP::Filter.eq('uid', username),
          attributes: %w[
            cn
          ]
        )
        result.size.positive?
      end

      def next_uidnumber
        uid_numbers = Hash.new(false)
        @ldap.search(
          base: @userbase,
          attributes: %w[
            uidNumber
          ]
        ) do |entry|
          uid_numbers[entry[:uidNumber]] = true
        end

        uid = @uid_start
        loop do
          break unless uid_numbers[uid.to_s]
          uid += 1
        end

        uid
      end

      def report_error(result)
        raise LdapError, format(
          '%<title>s: %<detail>s',
          title: result.message,
          detail: result.error_message
        )
      end

      def useradd(attrs)
        dn = format(
          'cn=%<cn>s,%<userbase>s',
          cn: attrs[:cn],
          userbase: @userbase
        )
        result = @ldap.add(
          dn: dn,
          attributes: attrs
        )
        unless result
          report_error(@ldap.get_operation_result)
        end
      end

      def groupadd(attrs)
        dn = format(
          'cn=%<cn>s,%<groupbase>s',
          cn: attrs[:cn],
          groupbase: @groupbase
        )
        result = @ldap.add(
          dn: dn,
          attributes: attrs
        )
        unless result
          report_error(@ldap.get_operation_result)
        end
      end
    end
  end
end
