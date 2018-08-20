# frozen_string_literal: true

require 'net-ldap'

module LdapAccountManage
  class LdapAccount
    def initialize(config)
      config[:ldap][:uri]

      @uid_start = config[:uid_start]
      @ldap = Net::LDAP.new(
        host: 'localhost'
      )
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
        break if uid_numbers[uid.to_s]
        uid += 1
      end

      uid + 1
    end

    def useradd(attrs)
      dn = 'cn=%<cn>s,%<userbase>s'.format(cn: attrs[:cn], userbase: @userbase)
      @ldap.add(
        dn: dn,
        attributes: attrs
      )
    end

    def groupadd(attrs)
      dn = 'cn=%<cn>s,%<groupbase>s'.format(
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
