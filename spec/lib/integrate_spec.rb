# frozen_string_literal: true

require_relative 'test_application'

RSpec.describe LdapAccountManage do
  describe 'running' do
    it 'is running without errors' do
      config_args = ['--config', File.expand_path('../assets/config.yaml', __dir__)]

      LdapAccountManageSpec.test_application.run([] + config_args)

      # check can run with TestInjector
      LdapAccountManageSpec.test_application.run(['config'] + config_args)
    end
  end
end
