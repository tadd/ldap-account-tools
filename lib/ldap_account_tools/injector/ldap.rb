# frozen_string_literal: true

require 'net-ldap'

module LdapAccountManage
  module SubInjector
    class LdapAccount
      def initialize(config)
        config['ldap']['uri']

        @uid_start = config['general']['uid_start']
        @ldap = Net::LDAP.new(
          host: 'localhost'
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
        @ldap.search(
          base: @userbase,
          filter: Net::LDAP::Filter.eq('uid', username),
          attributes: %w[
            cn
          ]
        )
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

        uid + 1
      end

      def useradd(attrs)
        dn = format(
          'cn=%<cn>s,%<userbase>s',
          cn: attrs[:cn],
          userbase: @userbase
        )
        @ldap.add(
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
        @ldap.add(
          dn: dn,
          attributes: attrs
        )
      end
    end
  end
end
