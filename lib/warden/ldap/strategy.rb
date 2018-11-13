# frozen_string_literal: true

require 'ostruct'
require 'net/ldap'
require 'warden'

module Warden
  module Ldap
    # Warden Strategy for LDAP
    class Strategy < Warden::Strategies::Base
      def initialize(*args)
        super

        @config = Warden::Ldap.configuration
      end

      # @return [Boolean ] true if all credentials have been provided.
      def valid?
        credentials.all? { |c| c.to_s !~ /^\s*$/ }
      end

      # Authenticates through the net-ldap gem, by connecting to the LDAP
      # server specified in the YAML configuration file and with the current
      # credentials.
      #
      # @return [Object, nil] user object
      def authenticate!
        connection = Warden::Ldap::Connection.new(@config, credentials_hash)
        user = connection.authenticate!

        if user
          success!(user)
        else
          fail!('Could not log in')
        end
      rescue Net::LDAP::LdapError
        fail!('Could not log in')
      end

      private

      # extracts the username and password from the params (this is the
      # same params on the RackRequest object which is typically delivered
      # directly from the login form)
      def credentials
        params.values_at('username', 'password')
      end

      def credentials_hash
        username, password = credentials

        { username: username, password: password }
      end
    end
  end
end
