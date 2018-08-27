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
      @runenv = RunEnv.new(conf)
      @ldap = LdapAccount.new(conf, @runenv)
      @cracklib = CrackLib.new(conf)
    end

    attr_reader :ldap
    attr_reader :cracklib
    attr_reader :runenv
  end
end
