# frozen_string_literal: true

module Warden
  module Ldap
    # LDAP User Factory
    class UserFactory
      def initialize(config)
        @config = config

        @user_attributes = { dn: 'dn' }.merge(@config.users.fetch(:attributes, {}))
        @group_attributes = { dn: 'dn' }.merge(@config.groups.fetch(:attributes, {}))
      end

      def search(username, ldap:)
        @config.logger.info("LDAP search for login: #{username.inspect}")

        ldap.auth(@config.username, @config.password)

        user = raw_user_search(username, ldap: ldap)

        return unless user

        result = @user_attributes.map { |k, v| [k, user.send(v.to_sym)] }.to_h
        result[:groups] = raw_group_search(result.fetch(:dn), ldap: ldap).map do |group|
          @group_attributes.map { |k, v| [k, group.send(v.to_sym)] }.to_h
        end
        result
      end

      private

      def raw_user_search(username, ldap:)
        options = options_for_user_search(username)

        @config.users.fetch(:base).each do |base|
          base = "#{base},#{@config.url.dn}"
          @config.logger.debug(" - searching for user in base: #{base.inspect}")
          results = ldap.search(base: base, **options)

          return results.first if results.count.positive?
        end

        nil
      end

      def options_for_user_search(username)
        filter = @config.users.fetch(:filter)
        filter = filter.gsub('$username', Net::LDAP::Filter.escape(username))

        {
          attributes: @user_attributes.values,
          filter: Net::LDAP::Filter::FilterParser.parse(filter),
          scope: lookup_scope(@config.users[:scope]),
          size: 1,
          return_result: true
        }
      end

      def raw_group_search(dn, ldap:)
        options = options_for_group_search(dn)

        @config.groups.fetch(:base).flat_map do |base|
          base = "#{base},#{@config.url.dn}"
          @config.logger.debug(" - searching for groups in base: #{base.inspect}")
          groups = ldap.search(base: base, **options)

          groups += groups.flat_map { |g| raw_group_search(g.dn, ldap: ldap) } if @config.groups.fetch(:nested, false)

          groups
        end
      end

      def options_for_group_search(dn)
        filter = @config.groups.fetch(:filter)
        filter = filter.gsub('$dn', Net::LDAP::Filter.escape(dn))

        {
          attributes: @group_attributes.values,
          filter: Net::LDAP::Filter::FilterParser.parse(filter),
          scope: lookup_scope(@config.groups[:scope]),
          return_result: true
        }
      end

      def lookup_scope(scope)
        case scope
        when 'base', 'base_object'
          Net::LDAP::SearchScope_BaseObject
        when 'level', 'single_level'
          Net::LDAP::SearchScope_SingleLevel
        when 'subtree', 'whole_subtree', nil
          Net::LDAP::SearchScope_WholeSubtree
        else
          raise ArgumentError, "unknown scope type #{scope}"
        end
      end
    end
  end
end
