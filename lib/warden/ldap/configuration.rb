# frozen_string_literal: true

module Warden
  module Ldap
    # Stores configuration information
    #
    # Configuration information is loaded from a configuration block defined
    # within the client application.
    #
    # @example Standard settings
    #   Warden::Ldap.configure do |c|
    #     c.config_file = 'path/to/warden_config.yml'
    #     # ...
    #     c.env 'test'
    #     c.logger Logger.new(STDOUT)
    #   end
    class Configuration
      Missing = Class.new(StandardError)

      class << self
        def define_setting(name)
          defined_settings << name
          attr_accessor name
        end

        def defined_settings
          @defined_settings ||= []
        end
      end

      # Path to the YAML config file which is required for connecting to the
      # LDAP server.
      # REQUIRED
      define_setting :config_file

      # Application environment. Determines which
      # environment to use from the YAML config_file.
      # Defaults to `Rails.env` if within Rails app
      define_setting :env

      # Logger to use for outputting info and errors.
      #
      # Defaults to output to standard out and standard error.
      define_setting :logger

      # Used to provide an array of environments to be considered as
      # test environments
      define_setting :test_environments

      def initialize
        @logger ||= Warden::Ldap::Logger
        @test_environments = nil
      end

      # @return [Object] the current environment set by the app
      #
      # Defaults to Rails.env if within Rails app and env is not set.
      def env
        @env ||= if defined?(Rails)
                   Rails.env
                 elsif @env.nil?
                   raise Missing, 'Must define Warden::Ldap.env'
                 end
      end

      # @return [Boolean] true if current environment is one of the ones listed
      #                   in test_environments
      def test_env?
        (@test_environments || []).include?(env)
      end
    end
  end
end
