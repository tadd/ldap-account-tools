# frozen_string_literal: true

require 'yaml'
require_relative 'util/base'

module LdapAccountManage
  class IllegalConfigError < StandardError; end

  class Config
    class << self
      def load(path)
        paths = default_paths

        config_obj =
          if !path.nil?
            begin
              YAML.load_file(path)
            rescue Errno::ENOENT => e
              raise IllegalConfigError, "Cannot load config: #{e.message}"
            end
          elsif paths.size.positive?
            YAML.load_file(paths[0])
          else
            {}
          end

        Config.new(config_obj)
      end

      def default_paths
        [
          '/etc/ldap-account-tools/config.yaml',
          'config.yaml',
        ].select { |path| File.exist?(path) }
      end

      def default_config
        hostname = Util.hostfullname
        basename = hostname.split('.').map { |s| 'dc=' + s }.join(',')

        {
          'general' => {
            'uid_start' => 2_000,
            'gid_start' => 30_000,
            'password_retry' => 3,
            'disable_check_password_file' => false,
            'data_dir' => '/var/lib/ldap-account-tools/data',
            'cache_dir' => '/var/lib/ldap-account-tools/cache',
            'lock_dir' => '/var/lock/ldap-account-tools',
          },
          'common' => {
          },
          'ldap' => {
            'host' => 'localhost',
            'port' => 389,
            'base' => basename,
            'tls' => 'off',
            'tls_options' => {},
            'root_info' => {
              'uid' => [0],
              'superuser_is_readable_user' => false,
              'auth_method' => 'simple',
              'dn' => 'cn=Manager,' + basename,
              'password_file' => '/etc/ldap-account-tools/private/ldap_password',
            },
            'user_info' => {
              'auth_method' => 'simple',
            },
          },
        }
      end
    end

    def initialize(datas)
      @datas = Util.deep_merge_hash(
        datas, Config.default_config
      )
    end

    def to_yaml
      YAML.dump(@datas).sub(/^---\n/, '')
    end

    def [](key)
      @datas[key]
    end
  end
end
