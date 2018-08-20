# frozen_string_literal: true

require 'thor'

require_relative 'config'

Dir.glob(
  File.expand_path('command/*.rb', __dir__)
).each do |entry|
  require_relative entry
end

module LdapAccountManage
  class Command < Thor
    def initialize(args, opts, config)
      super(args, opts, config)

      @config = Config.load(options['config'])
      @injector = Injector.load(@config)
    end

    class_option :config, type: :string,
      banner: 'CONFIG', aliases: [:c],
      desc: 'use as global configuration'

    include LdapAccountManage::SubCommand

    desc 'useradd [options] USER', 'add user'
    method_option :interactive, type: :boolean, default: true,
      desc: 'enable interactive mode'
    method_option :uidnumber, type: :number,
      desc: 'UID'
    method_option :gidnumber, type: :number,
      desc: 'GID'
    method_option :familyname, type: :string,
      banner: 'NAME',
      desc: 'Family Name'
    method_option :givenname, type: :string,
      banner: 'NAME',
      desc: 'Given Name'
    method_option :displayname, type: :string,
      banner: 'NAME',
      desc: 'Display Name'
    method_option :password, type: :string,
      banner: 'PASSWORD',
      desc: 'password (normally, you should input by tty)'
    method_option :mail, type: :string,
      banner: 'EMAIL',
      desc: 'email address'
    method_option :lang, type: :string,
      banner: 'LANG',
      desc: 'preferred language'
    method_option :phonenumber, type: :string,
      banner: 'PHONE',
      desc: 'telephone number'
    method_option :shell, type: :string,
      banner: 'SHELL',
      desc: 'login shell'
    method_option :homedir, type: :string,
      banner: 'DIR',
      desc: 'home directory'
    def useradd(username)
      command_useradd(username)
    end
  end
end
