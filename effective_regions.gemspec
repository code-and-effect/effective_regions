$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "effective_regions/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "effective_regions"
  s.version     = EffectiveRegions::VERSION
  s.email       = ["info@codeandeffect.com"]
  s.authors     = ["Code and Effect"]
  s.homepage    = "https://github.com/code-and-effect/effective_regions"
  s.summary     = "Create editable content regions within your existing, ordinary ActionView::Base views, and update content with an actually-good full-screen WYSIWYG editor."
  s.description = "Create editable content regions within your existing, ordinary ActionView::Base views, and update content with an actually-good full-screen WYSIWYG editor."
  s.licenses    = ['MIT']

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", [">= 3.2.0"]
  s.add_dependency 'effective_ckeditor', '>= 1.5.1'
  s.add_dependency "migrant"
  s.add_dependency "virtus"

  # s.add_development_dependency "factory_girl_rails"
  # s.add_development_dependency "rspec-rails"
  # s.add_development_dependency "shoulda-matchers"
  # s.add_development_dependency "sqlite3"
end
