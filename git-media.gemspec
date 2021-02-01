# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "git-media"
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Scott Chacon", "Alexander Lebedev", "Luxagen"]
  s.date = "2017-11-16"
  s.email = "hello@luxagen.com"
  s.executables = ["git-media"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
    "TODO"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "TODO",
    "VERSION",
    "bin/git-media",
    "git-media.gemspec",
    "lib/git-media.rb",
    "lib/git-media/clear.rb",
    "lib/git-media/filter-clean.rb",
    "lib/git-media/filter-smudge.rb",
    "lib/git-media/filter-branch.rb",
    "lib/git-media/helpers.rb",
    "lib/git-media/status.rb",
    "lib/git-media/sync.rb",
    "lib/git-media/transport.rb",
    "lib/git-media/transport/local.rb",
    "lib/git-media/transport/ssh.rb",
    "spec/media_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/luxagen/git-media"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.28"
  s.summary = "git-media"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<trollop>, [">= 0"])
    else
      s.add_dependency(%q<trollop>, [">= 0"])
    end
  else
    s.add_dependency(%q<trollop>, [">= 0"])
  end
end

