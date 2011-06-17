# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bitmask-attribute/version"

Gem::Specification.new do |s|
  s.name        = "bitmask-attribute"
  s.version     = Bitmask::Attribute::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jason L. Perry", "Nicolas Fouce", "Wojtek Mach"]
  s.email       = ["wojtekmach1@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Transparent manipulation of bitmask attributes.}

  s.rubyforge_project = "bitmask-attribute"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

