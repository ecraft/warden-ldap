# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'warden/ldap/version'

Gem::Specification.new do |spec|
  spec.name          = 'warden-ldap'
  spec.version       = Warden::Ldap::VERSION
  spec.authors       = ['Maher Hawash']
  spec.email         = ['gmhawash@gmail.com']
  spec.description   = 'Provides ldap strategy for Warden'
  spec.summary       = 'Provides ldap strategy for Warden'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_runtime_dependency 'net-ldap', '>= 0.16.0'
  spec.add_runtime_dependency 'psych', '>= 3.0.0'
  spec.add_runtime_dependency 'warden', '~> 1.2.1'
end
