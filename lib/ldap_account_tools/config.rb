# frozen_string_literal: true

require 'yaml'

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
            'data_dir' => '/var/lib/ldap-manage/data',
            'cache_dir' => '/var/lib/ldap-manage/cache',
            'lock_dir' => '/var/lock/ldap-manage'
          },
          'mail' => {
            'enable' => false,
            'host' => 'localhost',
            'port' => 25,
            'from' => "noreply@#{hostname}",
            'disable_tls' => false
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
