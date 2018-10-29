# frozen_string_literal: true

describe Warden::Ldap::Strategy do
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
    before :each do
      @env = env_with_params('/', 'username' => 'test', 'password' => 'secret')
      allow(subject).to receive_messages(valid?: true)
    end

    let(:test_connection) { double(Warden::Ldap::Connection) }

    it 'succeeds if the ldap connection succeeds' do
      allow(test_connection).to receive(:authenticate!).and_return(true)
      allow(test_connection).to receive(:ldap_param_value).with('samAccountName')
                                                          .and_return('samuel')
      allow(test_connection).to receive(:ldap_param_value).with('cn')
                                                          .and_return('Samuel')
      allow(test_connection).to receive(:ldap_param_value).with('mail')
                                                          .and_return('Samuel@swiftpenguin.com')

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
