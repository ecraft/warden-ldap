# frozen_string_literal: true

RSpec.describe Warden::Ldap::Strategy, :with_rack do
  before do
    Warden::Ldap.env = 'test'
    Warden::Ldap.configure do |c|
      c.config_file = File.join(__dir__, '../../fixtures/warden_ldap.yml')
    end
  end

  describe '#valid?' do
    it 'returns true if both username and password are passed in' do
      @env = env_with_params('/', 'username' => 'test', 'password' => 'secret')
      subject = described_class.new(@env)
      expect(subject).to be_valid
    end

    it 'returns false if password is missing' do
      @env = env_with_params('/', 'username' => 'test')
      subject = described_class.new(@env)
      expect(subject).to_not be_valid
    end

    it 'returns false if password is blank' do
      @env = env_with_params('/', 'username' => 'test', 'password' => '')
      subject = described_class.new(@env)
      expect(subject).to_not be_valid
    end
  end

  describe '#authenticate!' do
    before do
      env = env_with_params('/', 'username' => 'test', 'password' => 'secret')

      @strategy = described_class.new(env)
      allow(@strategy).to receive_messages(valid?: true)
      allow(@strategy).to receive(:connection).and_return(test_connection)
    end

    let(:test_connection) { double(Warden::Ldap::Connection) }

    it 'succeeds if the ldap connection succeeds' do
      allow(test_connection).to receive(:authenticate!)
                                  .with(username: 'test', password: 'secret')
                                  .and_return(true)

      expect(@strategy).to receive(:success!)

      @strategy.authenticate!
    end

    it 'fails if ldap connection fails' do
      allow(test_connection).to receive(:authenticate!).and_return(false)

      expect(@strategy).to receive(:fail!)

      @strategy.authenticate!
    end

    it 'fails if Net::LDAP::LdapError was raised' do
      allow(test_connection).to receive(:authenticate!).and_raise(Net::LDAP::LdapError)

      expect(@strategy).to receive(:fail!)

      @strategy.authenticate!
    end
  end
end
