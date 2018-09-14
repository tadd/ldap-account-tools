# frozen_string_literal: true

require 'thor'
require_relative '../config'
require_relative '../util/error'

module LdapAccountManage
  class Command
    desc 'config [option]', 'show config'
    method_option :default, type: :boolean, default: false,
      desc: 'default config'
    method_option :output, type: :string,
      desc: 'output file'
    def config
      config_output =
        if options[:default]
          Config.new({}).to_yaml
        else
          @config.to_yaml
        end

      if options[:output].nil?
        puts config_output
      else
        File.write(options[:output], config_output)
      end
    end
  end
end
