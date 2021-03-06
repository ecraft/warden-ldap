# frozen_string_literal: true

RSpec.describe Warden::Ldap::Configuration do
  it 'raises on missing file' do
    expect do
      Warden::Ldap::Configuration.new.load_configuration_file('', environment: 'test')
    end.to raise_error(Warden::Ldap::Configuration::Missing)
  end

  it 'raises on missing env' do
    expect do
      path = File.expand_path('../../fixtures/warden_ldap.yml', __dir__)

      Warden::Ldap::Configuration.new.load_configuration_file(path, environment: 'missing')
    end.to raise_error(Warden::Ldap::Configuration::Missing)
  end

  it 'parses YAML and returns content for current env' do
    path = File.expand_path('../../fixtures/warden_ldap.yml', __dir__)
    config = Warden::Ldap::Configuration.new
    config.load_configuration_file(path, environment: 'test')

    expect(config.users.fetch(:attributes)).to eq(username: "userId", email: "emailAddress")
  end

  context "SSL settings" do
    it 'parses SSL settings' do
      path = File.expand_path('../../fixtures/warden_ldap.yml', __dir__)
      config = Warden::Ldap::Configuration.new
      config.load_configuration_file(path, environment: 'production')

      expect(config.ssl).to eq(:start_tls)
    end

    it 'SSL is disabled by default' do
      path = File.expand_path('../../fixtures/warden_ldap.yml', __dir__)
      config = Warden::Ldap::Configuration.new
      config.load_configuration_file(path, environment: 'test')

      expect(config.ssl).to be_nil
    end
  end

  context 'with WARDEN_LDAP_PASSWORD=abc' do
    around do |example|
      old_val = ENV['LDAP_PASSWORD']
      ENV['LDAP_PASSWORD'] = 'abc'
      example.run
      ENV['LDAP_PASSWORD'] = old_val
    end

    it 'parses YAML and ERB and returns content for current env' do
      path = File.expand_path('../../fixtures/warden_ldap.yml.erb', __dir__)
      config = Warden::Ldap::Configuration.new
      config.load_configuration_file(path, environment: 'test')

      expect(config.password).to eq('abc')
    end
  end
end
