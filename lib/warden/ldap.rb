# frozen_string_literal: true

require 'warden/ldap/version'
require 'warden/ldap/configuration'
require 'warden/ldap/connection'
require 'warden/ldap/strategy'
require 'warden/ldap/fake_strategy'

module Warden
  # Warden LDAP strategy
  module Ldap
    class << self
      extend Forwardable
      Configuration.defined_settings.each do |setting|
        def_delegators :configuration, setting, "#{setting}="
      end

      def configure
        cfg = configuration

        yield cfg if block_given?

        cfg.finalize!

        Warden::Ldap.register
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def register
        strategy = if configuration.test_env?
                     Warden::Ldap::FakeStrategy
                   else
                     Warden::Ldap::Strategy
                   end

        Warden::Strategies.add(:ldap, strategy)
      end
    end
  end
end
