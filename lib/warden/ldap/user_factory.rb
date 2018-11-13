# frozen_string_literal: true

module Warden
  module Ldap
    # LDAP User Factory
    class UserFactory
      def initialize(config)
        @attributes = { dn: 'dn' }.merge(config.attributes)
        @config = config

        @klass = Struct.new(*@attributes.keys)
      end

      def search(username, ldap:)
        user = raw_search(username, ldap: ldap)

        return unless user

        values = @attributes.values.map { |v| user.send(v.to_sym) }

        @klass.new(*values)
      end

      private

      def raw_search(username, ldap:)
        @config.logger.info("LDAP search for login: #{username.inspect}")

        filter = @config.user_filter.gsub('$username', username)
        filter = Net::LDAP::Filter::FilterParser.parse(filter)

        ldap_entry = nil
        ldap.auth(@config.username, @config.password)
        ldap.search(filter: filter) { |entry| ldap_entry = entry }
        ldap_entry
      end
    end
  end
end
