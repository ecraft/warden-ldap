# frozen_string_literal: true

RSpec.describe Warden::Ldap, :with_rack do
  context 'environment' do
    describe '#env' do
      it 'returns Rails.env if defined' do
        Warden::Ldap.env = nil

        rails = double(env: :rails_environment)
        stub_const('Rails', rails)
        expect(described_class.env).to eq(:rails_environment)
      end

      it 'raises error if no environment defined' do
        Warden::Ldap.env = nil

        stub_const('ENV', {})
        expect { described_class.env }.to raise_error(Warden::Ldap::MissingEnvironment)
      end
    end

    describe '#test_env?' do
      it 'returns true if current env is one of test_envs' do
        subject.test_envs = %w[siesta fiesta]
        subject.env = 'siesta'
        expect(subject.test_env?).to eq true
      end

      it 'returns false if current env is one of test_envs' do
        subject.test_envs = %w[siesta fiesta]
        subject.env = 'nada'
        expect(subject.test_env?).to eq false
      end

      it 'returns false if test_envs is empty' do
        subject.test_envs = []
        subject.env = 'fiesta'
        expect(subject.test_env?).to eq false
      end

      it 'returns false if test_envs is undefined' do
        subject.test_envs = nil
        subject.env = 'fiesta'
        expect(subject.test_env?).to eq false
      end
    end
  end

  context "integration" do
    before do
      Warden::Ldap.env = 'test'

      described_class.configure do |c|
        c.config_file = File.join(__dir__, '../fixtures/warden_ldap.yml')
      end
    end

    it 'returns 401 if not authenticated' do
      env = env_with_params('/', 'username' => 'test')
      app = lambda do |env|
        env['warden'].authenticate!(:ldap)
      end

      result = setup_rack(app).call(env)
      expect(result.first).to eq 401
      expect(result.last).to eq ['You Fail!']
    end

    it 'returns 200 if authenticates properly' do
      env = env_with_params('/', 'username' => 'bobby', 'password' => 'joel')
      app = lambda do |env|
        env['warden'].authenticate!(:ldap)
        success_app.call(env)
      end

      allow_any_instance_of(Warden::Ldap::Connection).to receive_messages(authenticate!: true)
      allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('userId').and_return('samuel')
      allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('emailAddress').and_return('samuel@example.com')

      result = setup_rack(app).call(env)
      expect(result.first).to eq 200
      expect(result.last).to eq ['You Rock!']
    end

    it 'returns authenticated user information' do
      env = env_with_params('/', 'username' => 'bobby', 'password' => 'joel')
      app = lambda do |env|
        env['warden'].authenticate!(:ldap)
        success_app.call(env)
      end

      allow_any_instance_of(Warden::Ldap::Connection).to receive(:authenticate!)
                                                           .with(username: 'bobby', password: 'joel')
                                                           .and_return(OpenStruct.new(username: 'bobby'))

      result = setup_rack(app).call(env)
      expect(env['warden'].user.username).to eq 'bobby'
    end
  end
end
