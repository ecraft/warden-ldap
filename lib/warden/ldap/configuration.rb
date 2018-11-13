# frozen_string_literal: true

require 'logger'

module Warden
  module Ldap
    # Stores configuration information
    #
    # Configuration information is loaded from a configuration block defined
    # within the client application.
    #
    # @example Standard settings
    #   Warden::Ldap.configure do |c|
    #     c.env = 'test'
    #     c.config_file = 'path/to/warden_config.yml'
    #     # ...
    #     c.logger = Logger.new(STDOUT)
    #   end
    class Configuration
      Missing = Class.new(StandardError)

      class << self
        def define_setting(name)
          defined_settings << name

          define_method(name) do
            @configuration.fetch(name.to_s)
          end

          define_method("#{name}=") do |value|
            @configuration[name.to_s] = value
          end
        end

        def defined_settings
          @defined_settings ||= []
        end
      end

      define_setting :url
      define_setting :attributes
      define_setting :username
      define_setting :password
      define_setting :ssl

      def ssl
        @configuration['ssl'].to_sym if @configuration['ssl']
      end

      # Logger to use for outputting info and errors.
      #
      # Defaults to output to standard out and standard error.
      define_setting :logger

      attr_reader :configuration

      def initialize
        @configuration = {
          'logger' => Logger.new($stderr)
        }

        yield self if block_given?
      end

      def load_configuration_file(path, environment:)
        raw = Pathname(path).read
        yml = ERB.new(raw).result
        cfg = YAML.safe_load(yml, [], [], true)

        @configuration.merge!(cfg.fetch(environment))
      rescue KeyError
        raise Missing, "Could not find environment #{environment} in file #{path.inspect}"
      rescue Errno::ENOENT
        raise Missing, "Could not find configuration file #{path.inspect}"
      end
    end
  end
end
