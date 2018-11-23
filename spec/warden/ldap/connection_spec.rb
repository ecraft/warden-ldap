# frozen_string_literal: true

RSpec.describe Warden::Ldap::Connection do
  before { Warden::Ldap.env = 'test' }

  context 'with a fake config' do
    let(:config) do
      Warden::Ldap::Configuration.new do |cfg|
        cfg.url = 'ldap://ldap.example.com'
        cfg.users = {
          filter: "(&(objectClass=user)(emailAddress=$username))",
          attributes: { username: "username" }
        }
        cfg.groups = {}
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
        it 'authenticates and binds to ldap adapter' do
          ldap = double('Net::LDAP')
          user = { dn: 'sammy', username: 'Sammy' }

          expect_any_instance_of(Warden::Ldap::HostPool).to receive(:connect).and_return(ldap)
          expect_any_instance_of(Warden::Ldap::UserFactory).to receive(:search).with('bob', ldap: ldap).and_return(user)
          expect(ldap).to receive(:auth).with('sammy', 'secret')
          expect(ldap).to receive(:bind).and_return(true)

          subject = described_class.new(config)

          expect(subject.authenticate!(username: 'bob', password: 'secret')).to eq(user)
        end
      end
    end

    describe '#logger' do
      it 'comes with a default implementation' do
        subject = described_class.new(config)
        expect(subject.logger).to respond_to(:warn, :error, :info)
      end
    end
  end
end
