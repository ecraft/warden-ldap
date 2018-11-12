# frozen_string_literal: true

RSpec.describe Warden::Ldap::HostPool do
  context 'without a SRV record' do
    subject(:pool) { described_class.from_url('ldap://ldap.example.com/dc=com') }

    describe '#initialize' do
      it 'fills in hostname' do
        expect(pool.hosts.map(&:hostname)).to match_array %w[ldap.example.com]
      end

      it 'fills in default port' do
        expect(pool.hosts.map(&:port)).to match_array [389]
      end

      it 'fills in LDAP base' do
        expect(pool.base).to eq("dc=com")
      end
    end
  end
end

