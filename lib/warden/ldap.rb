# frozen_string_literal: true

require 'warden/ldap/version'
require 'warden/ldap/configuration'
require 'warden/ldap/connection'
require 'warden/ldap/strategy'

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
        Warden::Strategies.add(:ldap, Strategy)
      end
    end
  end
end
