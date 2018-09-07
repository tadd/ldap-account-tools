# frozen_string_literal: true

require 'ldap_account_tools'

require_relative 'test_injector'

module LdapAccountManageSpec
  module_function

  def test_application
    LdapAccountManage::Application.new(injector_base: TestInjector)
  end
end
