# frozen_string_literal: true

require 'resolv'
require 'uri'
require 'yaml'

require 'warden/ldap/host'

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
      def initialize(config, username: nil, password: nil, **options)
        @config = config.config

        @url = URI(@config.fetch('url'))

        @username = username
        @password = password

        options[:encryption] = @config['ssl'].to_sym if @config['ssl']

        @host_pool = Warden::Ldap::HostPool.from_url(@url, options: options)

        @ldap = @host_pool.connect

        @generic_credentials = @config['generic_credentials']
        @attribute = [@config['attributes']].flatten
      end

      # Searches LDAP directory for the parameters value passed in, e.g., 'cn'.
      #
      # @param param [String] key to look for
      # @return [Object, nil] value if found, or nil
      def ldap_param_value(param)
        ldap_entry = nil
        @ldap.search(filter: ldap_username_filter) { |entry| ldap_entry = entry }

        if ldap_entry
          value = ldap_entry.send(param)
          logger.info("Requested param #{param} has value #{value}")
          value = value.first if value.is_a?(Array) && (value.count == 1)
        else
          logger.error('Requested ldap entry does not exist')
          value = nil
        end
        value
      rescue NoMethodError
        logger.error("Requested param #{param} does not exist")
        nil
      end

      # Performs authentication with LDAP.
      #
      # Timeouts after configured `timeout` (default: 5).
      #
      # @return [Boolean, nil] true if authentication was successful,
      #   false otherwise, or nil if password was not provided
      def authenticate!
        return unless @password

        @ldap.auth(dn, @password)
        @ldap.bind
      end

      # @return [Boolean] true if user is authenticated
      def authenticated?
        authenticate!
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

      # Searches the LDAP for the login
      #
      # @return [Object] the LDAP entry found; nil if not found
      def search_for_login
        logger.info("LDAP search for login: #{@attribute}=#{@username}")
        ldap_entry = nil
        @ldap.auth(*@generic_credentials)
        @ldap.search(filter: ldap_username_filter) { |entry| ldap_entry = entry }
        ldap_entry
      end

      def ldap_username_filter
        filters = @attribute.map { |att| Net::LDAP::Filter.eq(att, @username) }
        filters.inject { |a, b| Net::LDAP::Filter.intersect(a, b) }
      end

      def find_ldap_user(ldap)
        logger.info("Finding user: #{dn}")
        ldap.search(base: dn,
                    scope: Net::LDAP::SearchScope_BaseObject).try(:first)
      end

      def dn
        logger.info("LDAP dn lookup: #{@attribute}=#{@username}")

        ldap_entry = search_for_login
        return unless ldap_entry

        ldap_entry.dn
      end
    end
  end
end
