# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldap_account_tools/version'

Gem::Specification.new do |spec|
  spec.name = 'ldap-account-tools'

  spec.version = LdapAccountManage::VERSION
  spec.date = Time.now.strftime('%Y-%m-%d')
  spec.license = 'MIT'

  spec.authors = 'mizunashi-mana'

  spec.summary = 'This tools provide some features for LDAP account management'
  spec.description = <<~DESCRIPTION
    This tools provide some features for LDAP accounts
  DESCRIPTION
  spec.homepage = 'https://github.com/mizunashi-mana/ldap-account-tools'

  spec.platform = Gem::Platform::RUBY

  spec.add_dependency('highline')
  spec.add_dependency('lockfile')
  spec.add_dependency('mail')
  spec.add_dependency('net-ldap')
  spec.add_dependency('rubylibcrack')
  spec.add_dependency('thor')

  spec.add_development_dependency('bundler')
  spec.add_development_dependency('pry')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop')

  spec.files = `git ls-files -z`.split("\x0")
  spec.test_files = `git ls-files -z -- {test,spec,features}/*`.split("\x0")
  spec.bindir = 'exe'
  spec.executables = `git ls-files -z -- exe/*`
    .split("\x0").map { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
