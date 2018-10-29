# frozen_string_literal: true

describe Warden::Ldap::FakeStrategy do
  subject { described_class.new(@env) }

  describe '#valid?' do
    it 'returns true if both username and password are passed in' do
      @env = env_with_params('/', 'username' => 'test', 'password' => 'secret')
      expect(subject).to be_valid
    end

    it 'returns false if password is missing' do
      @env = env_with_params('/', 'username' => 'test')
      expect(subject).to_not be_valid
    end

    it 'returns false if password is blank' do
      @env = env_with_params('/', 'username' => 'test', 'password' => '')
      expect(subject).to_not be_valid
    end
  end

  describe '#authenticte!' do
    it 'succeeds if credentials are valid' do
      @env = env_with_params('/', 'username' => 'test', 'password' => 'secret')
      expect(subject).to receive :success!
      subject.authenticate!
    end

    it 'fails if password is "fail"' do
      @env = env_with_params('/', 'username' => 'test', 'password' => 'fail')
      expect(subject).to receive :fail!
      subject.authenticate!
    end

    it 'fails if credentials are invalid' do
      @env = env_with_params('/', 'username' => 'test', 'password' => '')
      expect(subject).to receive :fail!
      subject.authenticate!
    end
  end
end
