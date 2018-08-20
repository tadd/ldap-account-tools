# frozen_string_literal: true

module LdapAccountManage
  class Injector
    class << self
      def load(config)
        Injector.new(config)
      end
    end

    def initialize(datas)
      @datas = Util.deep_merge_hash(
        datas, Config.default_config
      )
    end

    def get(key)
      @datas[key]
    end
  end
end
