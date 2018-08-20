# frozen_string_literal: true

require_relative 'command'

module LdapAccountManage
  class Application
    def run(argv = ARGV)
      config = {}

      Command.start(argv, config)
    end
  end

  module_function

  def application
    Application.new
  end
end
