# frozen_string_literal: true

require_relative "lib/tggl/version"

Gem::Specification.new do |spec|
  spec.name = "tggl"
  spec.version = Tggl::VERSION
  spec.authors = ["nick-keller"]
  spec.email = ["hello@tggl.io"]

  spec.summary = "Tggl client for Ruby"
  spec.homepage = "https://tggl.io/developers/sdks/ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tggl/ruby-tggl-client"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "xxhash", '~> 0.5'

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
  spec.add_development_dependency 'webmock', '~> 3.23'
end
