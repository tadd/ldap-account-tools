# frozen_string_literal: true

require 'socket'

module LdapAccountManage
  module Util
    module_function

    def hostfullname
      Socket.gethostbyname(Socket.gethostname).first
    rescue SocketError
      'localhost'
    end

    def deep_merge_hash(base, ext, oldbase = true)
      base.merge(ext) do |_k, oldv, newv|
        if oldv.is_a?(Hash) && newv.is_a?(Hash)
          deep_merge_hash(oldv, newv, oldbase)
        elsif oldbase
          oldv
        else
          newv
        end
      end
    end
  end
end
