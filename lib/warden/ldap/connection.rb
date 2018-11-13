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

        @attribute = [@config.attributes].flatten
      end

      # Performs authentication with LDAP.
      #
      # Timeouts after configured `timeout` (default: 5).
      #
      # @return [Boolean, nil] true if authentication was successful,
      #   false otherwise, or nil if password was not provided
      def authenticate!
        user = @user_factory.search(@username, ldap: @ldap)

        return unless user

        @ldap.auth(user.dn, @password)
        user if @ldap.bind
      end

      # @return [Boolean] true if user is authenticated
      def authenticated?
        !authenticate!.nil?
      end

      # Searches LDAP directory for login name.
      #
      # @@return [Boolean] true if found
      def valid_login?
        !search_for_login.nil?
      end

      private

      def ldap_host
        @ldap.host
      end
    end
  end
end
