# frozen_string_literal: true

require_relative 'lib/vistar_client/version'

Gem::Specification.new do |spec|
  spec.name = 'vistar_client'
  spec.version = VistarClient::VERSION
  spec.authors = ['Chayut Orapinpatipat']
  spec.email = ['chayut@canopusnet.com']

  spec.summary = 'Ruby client library for Vistar Media API'
  spec.description = 'A production-grade Ruby gem for interacting with the Vistar Media DOOH ' \
                     'advertising platform. Provides clean interfaces for ad serving, ' \
                     'proof-of-play submission, and campaign management.'
  spec.homepage = 'https://github.com/Sentia/vistar_client'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Sentia/vistar_client'
  spec.metadata['changelog_uri'] = 'https://github.com/Sentia/vistar_client/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/vistar_client'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/Sentia/vistar_client/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'faraday', '~> 2.7'
  spec.add_dependency 'faraday-retry', '~> 2.2'
end
