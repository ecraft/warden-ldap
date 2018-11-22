# frozen_string_literal: true

RSpec.describe Warden::Ldap::UserFactory do
  before do
    Warden::Ldap.logger = Logger.new('/dev/null')
    Warden::Ldap.env = 'test'
    Warden::Ldap.configure do |c|
      c.config_file = File.join(__dir__, '../../fixtures/warden_ldap.yml')
    end
  end

  subject { described_class.new(Warden::Ldap.configuration) }

  describe '#initialize' do
    it 'returns a UserFactory' do
      expect(subject).to be_a(Warden::Ldap::UserFactory)
    end
  end

  describe '#search' do
    let(:ldap) do
      double('the-ldap', auth: true)
    end

    context 'with no user found' do
      it 'returns nil' do
        allow(ldap).to receive(:search).and_return([])

        expect(subject.search('elmer', ldap: ldap)).to be_nil
      end

      it 'always adds "dn" to User Attributes' do
        expect(ldap).to receive(:search).with(hash_including(
                                                attributes: %w[dn] + %w[userId emailAddress]
                                              )).and_return([], [])

        subject.search('elmer', ldap: ldap)
      end
    end

    context 'with one user found' do
      let(:user) do
        double('the-user', dn: 'the-dn',
               userId: 'elmer1',
               emailAddress: 'elmer@example.com')
      end

      it 'returns a User hash with transformed attributes' do
        expect(ldap).to receive(:search).with(a_hash_including(size: 1)).and_return([user])
        # Ldap: find user's groups (zero groups)
        expect(ldap).to receive(:search).with(a_hash_including(attributes: %w(dn cn country ou),
                                                               scope: Net::LDAP::SearchScope_WholeSubtree)).and_return([])

        expect(subject.search('elmer', ldap: ldap)).to a_hash_including(
          dn: 'the-dn',
          username: 'elmer1',
          email: 'elmer@example.com'
        )
      end
    end

    context 'with one user found with a Group' do
      before do
        user = double('the-user', dn: 'the-dn',
                              userId: 'elmer1',
                              emailAddress: 'elmer@example.com')

        group = double('the-group', dn: 'the-group-dn',
                       cn: 'the-cn',
                       ou: 'Numerique et Informatique',
                       country: 'France')

        allow(ldap).to receive(:search).with(a_hash_including(size: 1)).and_return([user])

        group_search_args = a_hash_including(attributes: %w(dn cn country ou),
                                             scope: Net::LDAP::SearchScope_WholeSubtree)

        # RSpec detail: The Group lookup is nested, so we offer 2 return
        # values, first `[group]` then `[]`.
        allow(ldap).to receive(:search).with(group_search_args).and_return([group], [])
      end

      let(:user) do
        subject.search('elmer', ldap: ldap)
      end

      it 'returns a User hash with transformed attributes' do
        expect(user).to a_hash_including(
          dn: 'the-dn',
          username: 'elmer1',
          email: 'elmer@example.com'
        )
      end

      it 'returns a User hash with group attributes' do
        expect(user).to a_hash_including(
          groups: contain_exactly(hash_including(
            dn: 'the-group-dn',
            name: 'the-cn',
            organization: 'Numerique et Informatique',
            country: 'France'
          ))
        )
      end

      it 'returns a User hash with group matches' do
        expect(user).to a_hash_including(
          groups: contain_exactly(hash_including(france: true))
        )
      end

      it 'returns a User hash without group matches that do not match' do
        expect(user).to a_hash_including(
          groups: contain_exactly(hash_excluding(:user, :admin, :beta))
        )
      end
    end

    context 'scopes' do
      subject(:user_factory) do
        described_class.new(configuration_block)
      end

      context 'configured wrong for users/scope' do
        let(:configuration_block) do
          Warden::Ldap::Configuration.new do |cfg|
            cfg.logger = Logger.new('/dev/null')
            cfg.url = 'ldap://ldap.example.com'
            cfg.users = {
                scope: 'trololol',
                filter: '(&(objectClass=user)(emailAddress=$username))',
                attributes: { username: 'username' }
            }
            cfg.groups = {}
          end
        end

        it 'raises an ArgumentError' do
          expect do
            user_factory.search('elmer', ldap: ldap)
          end.to raise_error(ArgumentError, 'unknown scope type trololol')
        end
      end

      context 'configured wrong for groups/scope' do
        let(:configuration_block) do
          Warden::Ldap::Configuration.new do |cfg|
            cfg.logger = Logger.new('/dev/null')
            cfg.username = 'admin'
            cfg.password = 'sekret'
            cfg.url = 'ldap://ldap.example.com'
            cfg.users = {
                filter: '(&(objectClass=user)(emailAddress=$username))',
                attributes: { username: 'username' },
                base: ['ou=users']
            }
            cfg.groups = {
                filter: '(&(objectClass=group)(member=$dn))',
                scope: 'trololol'
            }
          end
        end

        it 'raises an ArgumentError' do
          user = double('the-user', dn: 'the-dn',
                        username: 'elmer1',
                        emailAddress: 'elmer@example.com')

          # Ldap: find user, so that we can then try to find their Groups,
          # and then fail on the unknown scope type.
          expect(ldap).to receive(:search).with(a_hash_including(size: 1)).and_return([user])

          expect do
            user_factory.search('elmer', ldap: ldap)
          end.to raise_error(ArgumentError, 'unknown scope type trololol')
        end
      end

      context 'when configured with "base_object"' do
        let(:configuration_block) do
          Warden::Ldap::Configuration.new do |cfg|
            cfg.logger = Logger.new('/dev/null')
            cfg.username = 'admin'
            cfg.password = 'sekret'
            cfg.url = 'ldap://ldap.example.com'
            cfg.users = {
                filter: '(&(objectClass=user)(emailAddress=$username))',
                attributes: { username: 'username' },
                base: ['ou=users']
            }
            cfg.groups = {
                filter: '(&(objectClass=group)(member=$dn))',
                scope: 'base_object',
                base: ['ou=users']
            }
          end
        end

        it 'raises nothing' do
          user = double('the-user', dn: 'the-dn',
                        username: 'elmer1',
                        emailAddress: 'elmer@example.com')

          # Ldap: find user, so that we can then try to find their Groups,
          # and then fail on the unknown scope type.
          allow(ldap).to receive(:search).with(a_hash_including(size: 1)).and_return([user])
          group = double('the-group', dn: 'the-group-dn',
                         cn: 'the-cn')

          expect(ldap).to receive(:search).with(a_hash_including(attributes: ['dn'], scope: Net::LDAP::SearchScope_BaseObject)).and_return([group])

          expect do
            user_factory.search('elmer', ldap: ldap)
          end.not_to raise_error
        end
      end

      context 'when configured with "single_level"' do
        let(:configuration_block) do
          Warden::Ldap::Configuration.new do |cfg|
            cfg.logger = Logger.new('/dev/null')
            cfg.username = 'admin'
            cfg.password = 'sekret'
            cfg.url = 'ldap://ldap.example.com'
            cfg.users = {
                filter: '(&(objectClass=user)(emailAddress=$username))',
                attributes: { username: 'username' },
                base: ['ou=users']
            }
            cfg.groups = {
                filter: '(&(objectClass=group)(member=$dn))',
                scope: 'single_level',
                base: ['ou=users']
            }
          end
        end

        it 'raises nothing' do
          user = double('the-user', dn: 'the-dn',
                        username: 'elmer1',
                        emailAddress: 'elmer@example.com')

          # Ldap: find user, so that we can then try to find their Groups,
          # and then fail on the unknown scope type.
          allow(ldap).to receive(:search).with(a_hash_including(size: 1)).and_return([user])
          group = double('the-group', dn: 'the-group-dn',
                         cn: 'the-cn')

          expect(ldap).to receive(:search).with(a_hash_including(attributes: ['dn'], scope: Net::LDAP::SearchScope_SingleLevel)).and_return([group])

          expect do
            user_factory.search('elmer', ldap: ldap)
          end.not_to raise_error
        end
      end
    end
  end
end
