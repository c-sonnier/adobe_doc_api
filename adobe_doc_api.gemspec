# frozen_string_literal: true

require_relative 'lib/adobe_doc_api/version'

Gem::Specification.new do |spec|
  spec.name = 'adobe_doc_api'
  spec.version = AdobeDocApi::VERSION
  spec.authors = ['Chris Sonnier']
  spec.email = ['christopher.sonnier@gmail.com']

  spec.summary = 'Ruby interface for Adobe PDF Services API Document Generation'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/c-sonnier/adobe_doc_api'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 1.8'
  spec.add_dependency 'faraday_middleware', '~> 1.2'
  spec.add_dependency 'jwt', '~> 2.3.0'
  spec.add_dependency 'openssl', '~> 2.2.1'
end
