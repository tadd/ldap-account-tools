# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldap_account_tools/version'
require 'ldap_account_tools/util/base'

Gem::Specification.new do |spec|
  spec.name = 'ldap-account-tools'

  spec.version = LdapAccountManage::VERSION
  spec.date = Time.now.strftime('%Y-%m-%d')
  spec.license = 'MIT'

  spec.authors = 'mizunashi-mana'
  spec.email = 'mizunashi-mana@noreply.git'

  spec.summary = 'This tools provide some features for LDAP account management'
  spec.description = <<~DESCRIPTION
    This tools provide some features for LDAP accounts
  DESCRIPTION
  spec.homepage = 'https://github.com/mizunashi-mana/ldap-account-tools'

  spec.platform = Gem::Platform::RUBY

  spec.add_dependency('highline', '~> 2.0')
  spec.add_dependency('lockfile', '~> 2.1')
  spec.add_dependency('mail', '~> 2.7')
  spec.add_dependency('net-ldap', '~> 0.16')
  spec.add_dependency('thor', '~> 0.20')

  spec.add_development_dependency('bundler', '~> 1.16')
  spec.add_development_dependency('pry', '~> 0.11')
  spec.add_development_dependency('rake', '~> 12.3')
  spec.add_development_dependency('rubocop', '~> 0.58')

  spec.bindir = 'exe'
  spec.require_paths = ['lib']
  spec.files =
    begin
      unless system('git status', out: '/dev/null', err: '/dev/null')
        raise Errno::ENOENT, 'Not a git repository'
      end
      `git ls-files -z`.split("\x0")
    rescue Errno::ENOENT
      STDERR.puts 'Use fallback find files, since not found a git repository'
      LdapAccountManage::Util.filelist('.')
        .reject { |f| f =~ /^(\.bundle|vendor|coverage|bin)/ }
    end
  spec.test_files = spec.files
    .select { |f| f =~ /^(test|features|spec)/ }
  spec.executables = spec.files
    .select { |f| f =~ /^(#{spec.bindir})/ }
    .map { |f| File.basename(f) }
end
