# frozen_string_literal: true

require 'thor'

require_relative 'config'
require_relative 'injector'

module LdapAccountManage
  class Command < Thor
    def initialize(args, opts, config)
      super(args, opts, config)

      @config = Config.load(options['config'])
      @injector = Injector.load(@config)
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
