# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

$thor_runner = true # rubocop:disable Style/GlobalVars

require 'rspec'
require 'simplecov'

SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/spec/'
  add_filter '/features/'

  add_group 'Commands', 'lib/ldap_account_tools/commands'
  add_group 'Utils', 'lib/ldap_account_tools/util'
end

require 'ldap_account_tools'
