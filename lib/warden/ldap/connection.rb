# frozen_string_literal: true

require 'resolv'
require 'yaml'

require 'warden/ldap/host_pool'
require 'warden/ldap/user_factory'

module Warden
  module Ldap
    # LDAP connection
    class Connection
      attr_reader :config
      attr_reader :host_pool
      attr_reader :user_factory

      def logger
        Warden::Ldap.logger
      end

      # @param config [Warden::Ldap::Configuration]
      def initialize(config)
        @config = config
        @user_factory = Warden::Ldap::UserFactory.new(@config)
        @host_pool = Warden::Ldap::HostPool.from_config(@config)
      end

      # Performs authentication with LDAP.
      #
      # @return [Hash, nil] User hash if authentication was successful or nil.
      def authenticate!(username:, password:)
        ldap = host_pool.connect
        user = user_factory.search(username, ldap: ldap)

        return unless user

        ldap.auth(user.fetch(:dn), password)

        user if ldap.bind
      end
    end
  end
end
