# frozen_string_literal: true

require 'thor'

require_relative 'config'
require_relative 'injector'

module LdapAccountManage
  class Command < Thor
    def initialize(args, opts, config)
      super(args, opts, config)

      if config[:injector_base].nil?
        config[:injector_base] = Injector
      end

      @config = Config.load(options['config'])
      @injector = config[:injector_base].load(@config)
    end

    class_option :config, type: :string,
      banner: 'CONFIG', aliases: [:c],
      desc: 'use as global configuration'
  end
end

Dir.glob(
  File.expand_path('command/*.rb', __dir__)
).each do |entry|
  require_relative entry
end
