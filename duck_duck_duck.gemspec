# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "duck_duck_duck"
  spec.version       = `cat VERSION`
  spec.authors       = ["da99"]
  spec.email         = ["i-hate-spam-1234567@mailinator.com"]
  spec.summary       = %q{Migrations for apps composed of mini-apps.}
  spec.description   = %q{
    I use it to keep track of various mini-apps
    within a larger app.
  }
  spec.homepage      = "https://github.com/da99/duck_duck_duck"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |file|
    file.index('bin/') == 0 && file != "bin/#{File.basename Dir.pwd}"
  }
  spec.executables   = [spec.name]
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry"           , "~> 0.9"
  spec.add_development_dependency "bundler"       , "~> 1.5"
  spec.add_development_dependency "bacon"         , "~> 1.2.0"
  spec.add_development_dependency "Bacon_Colored" , "~> 0.1"

  spec.add_development_dependency "sequel"        , "~> 4.13"
  spec.add_development_dependency "pg"            , "~> 0.16"
  spec.add_development_dependency "Exit_0"        , ">= 1.4.1"
end
