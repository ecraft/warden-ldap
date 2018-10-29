# frozen_string_literal: true

RSpec.describe Warden::Ldap::Configuration do
  describe '#env' do
    it 'returns Rails.env if defined' do
      rails = double(env: :rails_environemnt)
      stub_const('Rails', rails)
      expect(described_class.new.env).to eq(:rails_environemnt)
    end

    it 'raises error if no environemnt defined' do
      expect do
        described_class.new.env
      end.to raise_error Warden::Ldap::Configuration::Missing
    end
  end

  describe '#test_env?' do
    subject { described_class.new }
    it 'returns true if current env is one of test_environments' do
      subject.test_environments = %w[siesta fiesta]
      subject.env = 'siesta'
      expect(subject.test_env?).to eq true
    end

    it 'returns false if current env is one of test_environments' do
      subject.test_environments = %w[siesta fiesta]
      subject.env = 'nada'
      expect(subject.test_env?).to eq false
    end

    it 'returns false if test_environemnts is empty' do
      subject.test_environments = []
      subject.env = 'fiesta'
      expect(subject.test_env?).to eq false
    end

    it 'returns false if test_environemnts is undefined' do
      subject.env = 'fiesta'
      expect(subject.test_env?).to eq false
    end
  end
end
