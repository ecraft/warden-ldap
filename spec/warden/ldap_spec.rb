# frozen_string_literal: true

RSpec.describe Warden::Ldap do
  before :each do
    described_class.configure do |c|
      c.config = nil
      c.config_file = File.join(File.dirname(__FILE__), '../fixtures/warden_ldap.yml')
      c.env = 'test'
    end
  end

  it 'returns 401 if not authenticated' do
    env = env_with_params('/', 'username' => 'test')
    app = lambda do |env|
      env['warden'].authenticate(:ldap)
      throw(:warden)
    end
    result = setup_rack(app).call(env)
    expect(result.first).to eq 401
    expect(result.last).to eq ['You Fail!']
  end

  it 'returns 200 if authenticates properly' do
    env = env_with_params('/', 'username' => 'bobby', 'password' => 'joel')
    app = lambda do |env|
      env['warden'].authenticate(:ldap)
      success_app.call(env)
    end
    allow_any_instance_of(Warden::Ldap::Connection).to receive_messages(authenticate!: true)
    allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('samAccountName').and_return('samuel')
    allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('cn').and_return('Samuel')
    allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('mail').and_return('Samuel@swiftpenguin.com')
    result = setup_rack(app).call(env)
    expect(result.first).to eq 200
    expect(result.last).to eq ['You Rock!']
  end

  it 'returns authenticated user information' do
    env = env_with_params('/', 'username' => 'bobby', 'password' => 'joel')
    app = lambda do |env|
      env['warden'].authenticate(:ldap)
      success_app.call(env)
    end
    allow_any_instance_of(Warden::Ldap::Connection).to receive_messages(authenticate!: true)
    allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('samAccountName').and_return('bobby')
    allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('cn').and_return('Samuel')
    allow_any_instance_of(Warden::Ldap::Connection).to receive(:ldap_param_value).with('mail').and_return('Samuel@swiftpenguin.com')
    result = setup_rack(app).call(env)
    expect(env['warden'].user.username).to eq 'bobby'
    expect(env['warden'].user.name).to eq 'Samuel'
  end
end
