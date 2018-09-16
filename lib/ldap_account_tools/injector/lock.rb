# frozen_string_literal: true

require 'lockfile'

module LdapAccountManage
  module SubInjector
    class Lock
      def initialize(config)
        @lock_dir = config['general']['lock_dir']
      end

      def lock(filename, &block)
        Lockfile(File.join(@lock_dir, filename), &block)
      end

      ACCOUNT_MODIFY_LOCKFILE = 'account_modify.lock'
      def account_modify_lock(&block)
        lock(ACCOUNT_MODIFY_LOCKFILE, &block)
      end
    end
  end
end
