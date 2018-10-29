# frozen_string_literal: true

require 'ostruct'
require 'net/ldap'
require 'warden'

module Warden
  module Ldap
    # Warden Strategy for LDAP
    class Strategy < Warden::Strategies::Base
      # @return [Boolean ] true if all credentials have been provided.
      def valid?
        credentials.all? { |c| c.to_s !~ /^\s*$/ }
      end

      # Authenticates through the net-ldap gem, by connecting to the LDAP
      # server specified in the YAML configuration file and with the current
      # credentials.
      #
      # @return [OpenStruct, nil] user object constructed as an OpenStruct
      #                           with username, and name derived from the 'cn'
      #                           key in the LDAP directory, or nil on failure
      def authenticate!
        connection = Warden::Ldap::Connection.new(credentials_hash)
        response = connection.authenticate!

        if response
          success!(user_from_connection(connection))
        else
          fail!('Could not log in')
        end
      rescue Net::LDAP::LdapError
        fail!('Could not log in')
      end

      private

      def user_from_connection(connection)
        username = connection.ldap_param_value('samAccountName')
        name = connection.ldap_param_value('cn')
        email = connection.ldap_param_value('mail')
        OpenStruct.new(username: username,
                       name: name,
                       email: email)
      end

      # extracts the username and password from the params (this is the
      # same params on the RackRequest object which is typically delivered
      # directly from the login form)
      def credentials
        params.values_at('username', 'password')
      end

      def credentials_hash
        username, password = credentials
        { username: username,
          password: password }
      end
    end
  end
end
