# frozen_string_literal: true

require_relative 'command'

module LdapAccountManage
  class Application
    def initialize(injector_base: nil)
      @injector_base = injector_base
    end

    def run(argv = ARGV)
      config = {}

      unless @injector_base.nil?
        config[:injector_base] = @injector_base
      end

      Command.start(argv, config)
    end
  end

  module_function

  def application
    Application.new
  end
end
