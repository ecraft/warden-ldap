# frozen_string_literal: true

RSpec.describe Warden::Ldap::Connection do
  before(:each) do
    allow_any_instance_of(described_class).to receive(:config)
      .and_return('host' => '_ldap._tcp.example.com')
  end
  describe '#initialize' do
    let(:resource_one) { double(target: 'foo') }
    let(:resource_two) { double(target: 'bar') }

    it 'sets up host_addresses' do
      allow_any_instance_of(Resolv::DNS).to receive(:getresources)
        .with('_ldap._tcp.example.com', Resolv::DNS::Resource::IN::SRV)
        .and_return([resource_one, resource_two])
      subject = described_class.new
      expect(subject.host_addresses).to match_array %w[foo bar]
    end
  end

  describe '#authenticate!' do
    before(:each) do
      allow_any_instance_of(described_class).to receive(:host_addresses)
        .and_return(%w[foo bar])
    end

    it 'does nothing if no password present' do
      subject = described_class.new('username' => 'bob')
      expect(subject.authenticate!).to be_nil
    end

    it 'authenticates and binds to ldap adapter' do
      subject = described_class.new(username: 'bob', password: 'secret')
      allow(subject).to receive(:dn).and_return('Sammy')
      expect_any_instance_of(Net::LDAP).to receive(:auth).with('Sammy', 'secret')
      expect_any_instance_of(Net::LDAP).to receive(:bind).and_return(true)
      expect(subject.authenticate!).to eq true
    end

    it 'tries next host if first times out and logs both attempts' do
      subject = described_class.new(username: 'bob', password: 'secret')
      expect(subject.send(:ldap_host)).to eq 'foo'

      allow(subject).to receive(:connect!) do
        allow(subject).to receive(:connect!).and_return(true)
        raise Timeout::Error
      end

      expect(subject.logger).to receive(:info).twice
                                              .with(/Attempting LDAP connect with host (foo|bar)./)

      subject.authenticate!
      expect(subject.send(:ldap_host)).to eq 'bar'
    end

    it 'attempts each host twice and logs the failures' do
      subject = described_class.new(username: 'bob', password: 'secret')

      # four times since there are two hosts ['foo', 'bar'] and each gets tried twice
      expect(subject).to receive(:connect!)
        .exactly(4).times { raise Timeout::Error }
      expect(subject.logger).to receive(:error)
        .exactly(4).times
        .with(/Requested host timed out: (bar|foo); trying again with new host\./)

      expect(subject.authenticate!).to be_nil
    end
  end

  describe '#ldap_param_value' do
    subject { described_class.new }
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
