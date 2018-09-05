# frozen_string_literal: true

module LdapAccountManage
  module SubInjector
    class CrackLib
      def initialize(_config)
        @use_cracklib =
          begin
            require 'rubylibcrack'
            true
          rescue LoadError
            false
          end
      end

      def check_password(password)
        if @use_cracklib
          check = Cracklib::Password.new(password)
          {
            is_strong: check.strong?,
            message: check.message
          }
        else
          {
            is_strong: true
          }
        end
      end

      def crypt_hash(str)
        salt = '$6$' + Array.new(15).map { |_| rand(64) }.pack('C*').tr("\x00-\x3f", 'A-Za-z0-9./')
        str.crypt(salt)
      end
    end
  end
end
