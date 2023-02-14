# frozen_string_literal: true

require_relative "lib/commitgpt/version"

Gem::Specification.new do |spec|
  spec.name = "commitgpt"
  spec.version = CommitGpt::VERSION
  spec.authors = ["Peng Zhang"]
  spec.email = ["zpregister@gmail.com"]

  spec.summary = "A CLI AI that writes git commit messages for you."
  spec.description = "A CLI that writes your git commit messages for you with AI. Never write a commit message again."
  spec.homepage = "https://github.com/ZPVIP/commitgpt"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = spec.homepage

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "httparty", ">= 0.18.1"
  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
