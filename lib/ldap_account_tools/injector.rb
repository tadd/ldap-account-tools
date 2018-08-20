# frozen_string_literal: true

Dir.glob(
  File.expand_path('injector/*.rb', __dir__)
).each do |entry|
  require_relative entry
end

module LdapAccountManage
  class Injector
    class << self
      def load(config)
        Injector.new(config)
      end
    end

    include LdapAccountManage::SubInjector

    def initialize(conf)
      @ldap = LdapAccount.new(conf)
    end

    attr_reader :ldap
  end
end
