# frozen_string_literal: true

require 'lockfile'

module LdapAccountManage
  module Util
    module_function

    def lockfile(config, filename, &block)
      Lockfile(File.join(config['lock_dir'], filename), &block)
    end
  end
end
