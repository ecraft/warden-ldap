# frozen_string_literal: true

require 'uri'

module Warden
  module Ldap
    # LDAP server host
    class Host
      attr_reader :pool
      attr_reader :hostname
      attr_reader :port

      def initialize(pool:, hostname:, port:)
        @pool = pool
        @hostname = hostname
        @port = port
      end

      def connect
        Net::LDAP.new(@pool.options).tap do |connection|
          connection.host = @hostname
          connection.port = @port
          connection.base = @pool.base
        end
      end
    end

    # A pool of LDAP hosts
    class HostPool
      attr_reader :hosts
      attr_reader :base
      attr_reader :options

      def initialize(base:, options: {})
        @base = base
        @options = options

        @hosts = []
      end

      def self.from_url(url, options: {})
        url = URI(url) if url.is_a? String

        new(base: url.dn, options: options).tap do |pool|
          pool.hosts << Host.new(pool: pool, hostname: url.host, port: url.port)
        end
      end

      def connect
        @hosts.first.connect
      end
    end
  end
end
