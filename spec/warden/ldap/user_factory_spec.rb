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

    context 'with no user found' do
      it 'returns nil' do
        allow(ldap).to receive(:search).and_return([])

        expect(subject.search('elmer', ldap: ldap)).to be_nil
      end

      it 'always adds "dn" to the list of User Attributes' do
        expect(ldap).to receive(:search).with(hash_including(
                                                  attributes: %w[dn] + %w[userId emailAddress]
                                              )).and_return([])

        subject.search('elmer', ldap: ldap)
      end
    end

    context 'with one user found' do
      it 'returns a transformed User attributes hash' do
        user = double('the-user', dn: 'the-dn',
                                  userId: 'elmer1',
                                  emailAddress: 'elmer@example.com')
        # Ldap: find user
        expect(ldap).to receive(:search).with(a_hash_including(size: 1)).and_return([user])
        # Ldap: find user's groups
        expect(ldap).to receive(:search).with(a_hash_including(attributes: ['dn'],
                                                               scope: Net::LDAP::SearchScope_WholeSubtree)).and_return([])

        expect(subject.search('elmer', ldap: ldap)).to a_hash_including(
                                                           dn: 'the-dn',
                                                           username: 'elmer1',
                                                           email: 'elmer@example.com',
                                                           groups: anything,
                                                       )
      end
    end

    context 'with a bad users/scope'
    context 'with a bad groups/scope'
  end
end
