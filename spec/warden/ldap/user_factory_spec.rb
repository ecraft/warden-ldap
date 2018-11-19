# frozen_string_literal: true

RSpec.describe Warden::Ldap::UserFactory do
  before do
    Warden::Ldap.logger = double.as_null_object
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
    let(:ldap) do
      double('the-ldap', auth: true)
    end
    it 'returns nil if user not found' do
      allow(ldap).to receive(:search).and_return([])

      expect(subject.search('elmer', ldap: ldap)).to be_nil
    end

    it 'always adds "dn" to the list of User Attributes' do
      expect(ldap).to receive(:search).with(hash_including(
                                              attributes: %w[dn] + %w[userId emailAddress]
                                            )).and_return([])

      subject.search('elmer', ldap: ldap)
    end

    context 'with a bad users/scope'
    context 'with a bad groups/scope'
  end
end
