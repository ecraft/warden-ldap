# frozen_string_literal: true

RSpec.describe Warden::Ldap::Connection do
  before { Warden::Ldap.env = 'test' }

  context 'with a fake config' do
    let(:config) do
      Warden::Ldap::Configuration.new do |cfg|
        cfg.attributes = []
        cfg.url = 'ldap://ldap.example.com'
      end
    end

    describe '#authenticate!' do
      describe '#initialize' do
        it 'sets up hosts for regular url' do
          subject = described_class.new(config)
          expect(subject.host_pool.hosts.map(&:hostname)).to match_array %w[ldap.example.com]
        end

        it 'sets up default port for regular url' do
          subject = described_class.new(config)
          expect(subject.host_pool.hosts.map(&:port)).to match_array [389]
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
end
