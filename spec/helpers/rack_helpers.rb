# frozen_string_literal: true

require 'warden'
require 'warden/ldap'
require 'rack'
module Warden::Ldap::Helpers
  module RackHelpers
    def env_with_params(path = '/', params = {}, env = {})
      method = params.delete(:method) || 'GET'
      env = { 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => method.to_s }.merge(env)
      Rack::MockRequest.env_for("#{path}?#{Rack::Utils.build_query(params)}", env)
    end

    def setup_rack(app = nil, opts = {}, &block)
      app ||= block if block_given?

      opts[:failure_app]         ||= failure_app
      opts[:default_strategies]  ||= [:ldap]
      opts[:default_serializers] ||= [:session]
      blk = opts[:configurator] || proc {}

      Rack::Builder.new do
        use opts[:session] || RackHelpers::Session
        use Warden::Manager, opts, &blk
        run app
      end
    end

    def valid_response
      Rack::Response.new('OK').finish
    end

    def failure_app
      ->(_e) { [401, { 'Content-Type' => 'text/plain' }, ['You Fail!']] }
    end

    def success_app
      ->(_e) { [200, { 'Content-Type' => 'text/plain' }, ['You Rock!']] }
    end

    class Session
      attr_accessor :app
      def initialize(app, _configs = {})
        @app = app
      end

      def call(e)
        e['rack.session'] ||= {}
        @app.call(e)
      end
    end # session
  end
end
