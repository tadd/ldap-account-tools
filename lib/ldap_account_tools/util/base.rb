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

    def deep_merge_hash(base, ext, oldbase: true)
      base.merge(ext) do |_k, oldv, newv|
        if oldv.is_a?(Hash) && newv.is_a?(Hash)
          deep_merge_hash(oldv, newv, oldbase: oldbase)
        elsif oldbase
          oldv
        else
          newv
        end
      end
    end

    def filelist(dir, is_rec: true)
      result = []

      Dir.each_child(dir) do |f|
        path = File.join(dir, f)
        if File.file?(path)
          result.push(path)
        elsif is_rec && Dir.dir?(path)
          result += filelist(path, is_rec: is_rec)
        end
      end

      result
    end
  end
end
