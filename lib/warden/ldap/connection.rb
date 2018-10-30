# frozen_string_literal: true

require 'yaml'
require 'resolv'
module Warden
  module Ldap
    # LDAP connection
    class Connection
      attr_reader :ldap, :login, :host_addresses

      def logger
        Warden::Ldap.logger
      end

      # Uses the warden_ldap.yml file to initialize the net-ldap connection.
      #
      # @param options [Hash]
      # @option options [String] :username username to use for logging in
      # @option options [String] :password password to use for logging in
      # @option options [String] :encryption 'ssl' to use secure server
      def initialize(options = {})
        @login = options.delete(:username)
        @password = options.delete(:password)

        options[:encryption] = config['ssl'].to_sym if config['ssl']

        set_host_addresses

        @ldap = Net::LDAP.new(options)
        @ldap.host = host_addresses.first
        @ldap.port = config['port']
        @ldap.base = config['base']

        @generic_credentials = config['generic_credentials']
        @attribute = [config['attributes']].flatten
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
        result = nil
        count = 0
        length = host_addresses.length

        while count < length * 2
          begin
            logger.info("Attempting LDAP connect with host #{@ldap.host}.")
            Timeout.timeout(config.fetch('timeout', 5).to_i) { result = connect! }
            break
          rescue Errno::ETIMEDOUT, Timeout::Error
            logger.error("Requested host timed out: #{@ldap.host}; trying again with new host.")
            count += 1
            @ldap.host = host_addresses[count % length]
          end
        end

        result
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

      def connect!
        return unless @password

        @ldap.auth(dn, @password)
        @ldap.bind
      end

      # Sets @host_addresses to an array of IP addresses
      def set_host_addresses
        @host_addresses = Resolv::DNS.open do |dns|
          dns.getresources(config.fetch('host') { raise KeyError, 'Required configuration key "host" not found.' }, Resolv::DNS::Resource::IN::SRV)
             .map(&:target)
             .map(&:to_s)
        end
      end

      def ldap_host
        @ldap.host
      end

      # Searches the LDAP for the login
      #
      # @return [Object] the LDAP entry found; nil if not found
      def search_for_login
        logger.info("LDAP search for login: #{@attribute}=#{@login}")
        ldap_entry = nil
        @ldap.auth(*@generic_credentials)
        @ldap.search(filter: ldap_username_filter) { |entry| ldap_entry = entry }
        ldap_entry
      end

      def ldap_username_filter
        filters = @attribute.map { |att| Net::LDAP::Filter.eq(att, @login) }
        filters.inject { |a, b| Net::LDAP::Filter.intersect(a, b) }
      end

      def find_ldap_user(ldap)
        logger.info("Finding user: #{dn}")
        ldap.search(base: dn,
                    scope: Net::LDAP::SearchScope_BaseObject).try(:first)
      end

      # Returns the configuration for configured environment.
      #
      # @return [Hash] the section of the YAML config for the current env
      def config
        file = Pathname(Warden::Ldap.config_file)
        return {} unless file.exist?

        text = ERB.new(file.read).result
        @config = YAML.safe_load(text, [], [], true)[Warden::Ldap.env]
      end

      def dn
        logger.info("LDAP dn lookup: #{@attribute}=#{@login}")

        ldap_entry = search_for_login
        return unless ldap_entry

        ldap_entry.dn
      end
    end
  end
end
