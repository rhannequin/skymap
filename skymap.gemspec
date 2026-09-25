# frozen_string_literal: true

require_relative "lib/skymap/version"

Gem::Specification.new do |spec|
  spec.name = "skymap"
  spec.version = Skymap::VERSION
  spec.authors = ["Rémy Hannequin"]
  spec.email = ["remy.hannequin@gmail.com"]

  spec.summary = "Sky maps in Ruby."
  spec.description = "Skymap is a Ruby library for generating maps of the sky."
  spec.homepage = "https://github.com/rhannequin/skymap"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "astronoby", "~> 0.10"

  spec.add_development_dependency "irb", "~> 1.18"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.88"
  spec.add_development_dependency "standard", "~> 1.54"
end
