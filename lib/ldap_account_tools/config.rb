# frozen_string_literal: true

require 'yaml'
require_relative 'util/base'

module LdapAccountManage
  class Config
    class << self
      def load(path)
        paths = default_paths

        config_obj =
          if !path.nil?
            YAML.load_file(path)
          elsif paths.size.positive?
            YAML.load_file(paths[0])
          else
            {}
          end

        Config.new(config_obj)
      end

      def default_paths
        [
          '/etc/ldap-manage/config.yaml',
          'config.yaml'
        ].select { |path| File.exist?(path) }
      end

      def default_config
        hostname = Util.hostfullname

        {
          'general' => {
            'use_cracklib' => true,
            'uid_start' => 2000,
            'data_dir' => '/var/lib/ldap-account-tools/data',
            'cache_dir' => '/var/lib/ldap-account-tools/cache',
            'lock_dir' => '/var/lock/ldap-account-tools'
          },
          'common' => {
            'mailhost' => hostname
          },
          'mail' => {
            'enable' => false,
            'host' => 'localhost',
            'port' => 25,
            'from' => "noreply@#{hostname}",
            'disable_tls' => false
          },
          'ldap' => {
            'host' => 'localhost',
            'port' => 389,
            'auth_method' => 'simple',
            'base' => 'dc=iwasaki-local,dc=cs,dc=uec,dc=ac,dc=jp'
          }
        }
      end
    end

    def initialize(datas)
      @datas = Util.deep_merge_hash(
        datas, Config.default_config
      )
    end

    def [](key)
      @datas[key]
    end
  end
end
