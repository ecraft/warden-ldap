# frozen_string_literal: true

RSpec.describe Warden::Ldap::Connection do
  context 'with a fake config' do
    let(:config) do
      Warden::Ldap::Configuration.new do |cfg|
        cfg.config = { 'url' => 'ldap://ldap.example.com' }
      end.finalize!
    end

    describe '#authenticate!' do
      describe '#initialize' do
        it 'sets up hosts for regular url' do
          subject = described_class.new(config)
          expect(subject.hosts.map(&:hostname)).to match_array %w[ldap.example.com]
        end

        it 'sets up default port for regular url' do
          subject = described_class.new(config)
          expect(subject.hosts.map(&:port)).to match_array [389]
        end
      end

      describe '#authenticate!' do
        xit 'does nothing if no password present' do
          subject = described_class.new('username' => 'bob')
          expect(subject.authenticate!).to be_nil
        end

        it 'authenticates and binds to ldap adapter' do
          subject = described_class.new(config, username: 'bob', password: 'secret')
          allow(subject).to receive(:dn).and_return('Sammy')
          expect_any_instance_of(Net::LDAP).to receive(:auth).with('Sammy', 'secret')
          expect_any_instance_of(Net::LDAP).to receive(:bind).and_return(true)
          expect(subject.authenticate!).to eq true
        end
      end

      describe '#ldap_param_value' do
        subject { described_class.new(config) }

        let(:ldap) { Net::LDAP.new }
        let(:entry) { Net::LDAP::Entry.new('ldap_entry') }

        it 'returns value if ldap entry found' do
          allow(Net::LDAP).to receive(:new).and_return(ldap)

          entry['cn'] = 'code name'
          allow(ldap).to receive(:search).and_yield(entry)
          expect(subject.logger).to receive(:info).with('Requested param cn has value ["code name"]')
          expect(subject.ldap_param_value(:cn)).to eq 'code name'
        end

        it 'returns nil if ldap entry does not have attribute' do
          allow(Net::LDAP).to receive(:new).and_return(ldap)

          expect(ldap).to receive(:search).and_yield(entry)
          expect(subject.logger).to receive(:error).with('Requested param cn does not exist')
          expect(subject.ldap_param_value(:cn)).to be_nil
        end

        it 'returns nil if ldap entry not found' do
          allow(Net::LDAP).to receive(:new).and_return(ldap)

          expect(ldap).to receive(:search)
          expect(subject.logger).to receive(:error).with('Requested ldap entry does not exist')
          expect(subject.ldap_param_value(:cn)).to be_nil
        end
      end
    end
  end

  context 'with no special config' do
    describe '#config' do
      it 'raises on missing file' do
        config = Warden::Ldap::Configuration.new do |cfg|
          cfg.config_file = ''
        end

        expect { config.finalize! }.to raise_error(Warden::Ldap::Configuration::Missing)
      end
    end

    it 'parses YAML and returns content for current env' do
      config = Warden::Ldap::Configuration.new do |cfg|
        cfg.config_file = File.expand_path('../../fixtures/warden_ldap.yml', __dir__)
        cfg.env = 'test'
      end.finalize!

      expect(config.config).to match(hash_including('attributes' => contain_exactly('uid', 'cn', 'mail', 'samAccountName')))
    end

    context 'with WARDEN_LDAP_PASSWORD=abc' do
      around do |example|
        old_val = ENV['WARDEN_LDAP_PASSWORD']
        ENV['WARDEN_LDAP_PASSWORD'] = 'abc'
        example.run
        ENV['WARDEN_LDAP_PASSWORD'] = old_val
      end

      it 'parses YAML and ERB and returns content for current env' do
        config = Warden::Ldap::Configuration.new do |cfg|
          cfg.config_file = File.expand_path('../../fixtures/warden_ldap.yml.erb', __dir__)
          cfg.env = 'test'
        end.finalize!

        expect(config.config).to match(hash_including('password' => 'abc'))
      end
    end
  end
end
