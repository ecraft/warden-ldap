# frozen_string_literal: true

require 'warden/ldap/version'
require 'warden/ldap/configuration'
require 'warden/ldap/connection'
require 'warden/ldap/strategy'
require 'warden/ldap/fake_strategy'

module Warden
  # Warden LDAP strategy
  module Ldap
    MissingEnvironment = Class.new(StandardError)

    class << self
      extend Forwardable

      Configuration.defined_settings.each do |setting|
        def_delegators :configuration, setting, "#{setting}="
      end

      attr_writer :env

      # @return [Object] the current environment set by the app
      #
      # Defaults to Rails.env if within Rails app and env is not set.
      def env
        @env ||= Rails.env if defined?(Rails)
        @env ||= ENV['RACK_ENV'] if ENV['RACK_ENV'] && ENV['RACK_ENV'] != ''

        raise MissingEnvironment, 'Must define Warden::Ldap.env' unless @env

        @env
      end

      attr_writer :test_envs

      def test_envs
        @test_envs || []
      end

      # @return [Boolean] is current environment is listed in test_envs?
      def test_env?
        test_envs.include?(env)
      end

      def configure
        yield self if block_given?

        Warden::Ldap.register
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def config_file=(path)
        configuration.load_configuration_file(path, environment: env)
      end

      def register
        strategy = test_env? ? FakeStrategy : Strategy

        Warden::Strategies.add(:ldap, strategy)
      end
    end
  end
end
