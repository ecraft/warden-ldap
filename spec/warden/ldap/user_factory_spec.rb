# frozen_string_literal: true

RSpec.describe Warden::Ldap::UserFactory do
  before do
    Warden::Ldap.env = 'test'
    Warden::Ldap.configure do |c|
      c.config_file = File.join(__dir__, '../../fixtures/warden_ldap.yml')
    end
  end

  subject { described_class.new(Warden::Ldap.configuration) }

  describe '#initialize' do
    it 'returns a UserFactory' do
      expect(subject).to be_a(Warden::Ldap::UserFactory)
    end
  end

  describe '#search' do
    it 'returns nil if user not found'

    context 'with a bad users/scope'
    context 'with a bad groups/scope'
  end
end
