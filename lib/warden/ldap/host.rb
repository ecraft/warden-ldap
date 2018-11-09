# frozen_string_literal: true

require 'uri'

module Warden
  module Ldap
    # LDAP host
    Host = Struct.new(:hostname, :port) do
      def self.list_from_url(url)
        host = new(url.host, url.port)

        [host]
      end
    end
  end
end
