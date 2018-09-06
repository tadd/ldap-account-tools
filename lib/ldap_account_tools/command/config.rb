# frozen_string_literal: true

require 'thor'
require_relative '../config'
require_relative '../util/error'

module LdapAccountManage
  class Command
    desc 'config [option]', 'show config'
    method_option :default, type: :boolean, default: false,
      desc: 'default config'
    def config
      if options[:default]
        puts Config.new({}).to_yaml
      else
        puts @config.to_yaml
      end
    end
  end
end
