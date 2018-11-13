# frozen_string_literal: true

RSpec.describe Warden::Ldap::Strategy do
  before do
    Warden::Ldap.env = 'test'
    Warden::Ldap.configure do |c|
      c.config_file = File.join(__dir__, '../../fixtures/warden_ldap.yml')
    end
  end

  subject { described_class.new(@env) }

  describe '#valid?' do
    it 'returns true if both username and password are passed in' do
      @env = env_with_params('/', 'username' => 'test', 'password' => 'secret')
      expect(subject).to be_valid
    end

    it 'returns false if password is missing' do
      @env = env_with_params('/', 'username' => 'test')
      expect(subject).to_not be_valid
    end

    it 'returns false if password is blank' do
      @env = env_with_params('/', 'username' => 'test', 'password' => '')
      expect(subject).to_not be_valid
    end
  end

  describe '#authenticte!' do
    before do
      @env = env_with_params('/', 'username' => 'test', 'password' => 'secret')
      allow(subject).to receive_messages(valid?: true)
    end

    let(:test_connection) { double(Warden::Ldap::Connection) }

    it 'succeeds if the ldap connection succeeds' do
      allow(test_connection).to receive(:authenticate!).and_return(true)

      allow(test_connection).to receive(:ldap_param_value).with('userId').and_return('samuel')
      allow(test_connection).to receive(:ldap_param_value).with('emailAddress').and_return('samuel@example.com')

      allow(Warden::Ldap::Connection).to receive(:new).and_return(test_connection)
      expect(subject).to receive(:success!)
      subject.authenticate!
    end

    it 'fails if ldap connection fails' do
      allow(test_connection).to receive(:authenticate!).and_return(false)
      allow(Warden::Ldap::Connection).to receive(:new).and_return(test_connection)
      expect(subject).to receive(:fail!)
      subject.authenticate!
    end

    it 'fails if Net::LDAP::LdapError was raised' do
      allow(test_connection).to receive(:authenticate!).and_raise(Net::LDAP::LdapError)
      allow(Warden::Ldap::Connection).to receive(:new).and_return(test_connection)
      expect(subject).to receive(:fail!)
      subject.authenticate!
    end
  end
end
