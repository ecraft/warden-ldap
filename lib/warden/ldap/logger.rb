# frozen_string_literal: true

module Warden
  module Ldap
    # Logger which outputs INFO messages to standard out,
    # and ERROR messages to standard error.
    class Logger
      class << self
        def info(message)
          $stdout.puts(message)
        end

        def error(message)
          warn(message)
        end
      end
    end
  end
end
