# frozen_string_literal: true

require 'ostruct'
require 'warden'

module Warden
  module Ldap
    # An always-working Strategy, for use in testing.
    #
    # If given a user and a password, it will call success!.
    #
    # If given the password "fail", it will call fail!.
    class FakeStrategy < Warden::Ldap::Strategy
      def authenticate!
        username, password = credentials
        if valid? && !password.casecmp('fail').zero?
          user = OpenStruct.new(username: username,
                                email: "#{username}@fakeuser.com")
          success!(user)
        else
          fail!('Could not log in')
        end
      end
    end
  end
end
