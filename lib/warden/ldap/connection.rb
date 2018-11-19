# frozen_string_literal: true

require 'resolv'
require 'yaml'

require 'warden/ldap/host_pool'
require 'warden/ldap/user_factory'

module Warden
  module Ldap
    # LDAP connection
    class Connection
      attr_reader :ldap, :config, :host_pool

      def logger
        Warden::Ldap.logger
      end

      # Uses the warden_ldap.yml file to initialize the net-ldap connection.
      #
      # @param options [Hash]
      # @option options [String] :url url for ldap server
      # @option options [String] :username username to use for logging in
      # @option options [String] :password password to use for logging in
      # @option options [String] :encryption 'ssl' to use secure server
      def initialize(config, username:, password: nil, **options)
        @config = config

        @username = username
        @password = password

        @user_factory = Warden::Ldap::UserFactory.new(@config)

        options[:encryption] = @config.ssl

        @host_pool = Warden::Ldap::HostPool.from_url(@config.url, options: options)

        @ldap = @host_pool.connect
      end

      # Performs authentication with LDAP.
      #
      # Timeouts after configured `timeout` (default: 5).
      #
      # @return [Object, nil] User object if authentication was successful,
      #   otherwise nil.
      def authenticate!
        user = @user_factory.search(@username, ldap: @ldap)

        return unless user

        @ldap.auth(user.fetch(:dn), @password)
        user if @ldap.bind
      end
    end
  end
end
