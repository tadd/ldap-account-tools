# frozen_string_literal: true

require 'ldap_account_tools/injector'
require 'ostruct'

module LdapAccountManageSpec
  class TestInjector
    class << self
      def load(config)
        TestInjector.new(config)
      end
    end

    include LdapAccountManage::SubInjector

    def initialize(conf)
      @runenv = RunEnv.new(conf)
      @ldap = LdapAccount.new(conf, ldap: LdapInstanceMock)
      @cracklib = CrackLib.new(conf)
    end

    attr_reader :ldap
    attr_reader :cracklib
    attr_reader :runenv
  end

  class LdapInstanceMock
    def initialize(host:, port:, auth:)
      @host = host
      @port = port
      @auth = auth
    end

    def search(base:, filter:, attributes:)
      result = []

      if base =~ /ou=people,/ && filter.to_s =~ /uid=existsuser/
        entry = {}
        attributes.each do |attribute|
          case attribute
          when 'cn' then entry[:cn] = 'existsuser'
          when 'uidNumber' then entry[:uidnumber] = 2500
          end
        end

        entry = OpenStruct.new(entry)
        if block_given?
          entry = yield entry
        end

        result.push(entry)
      end

      {
        status: true,
        content: result
      }
    end

    def add(_options)
      result = []

      {
        status: true,
        content: result
      }
    end
  end
end
