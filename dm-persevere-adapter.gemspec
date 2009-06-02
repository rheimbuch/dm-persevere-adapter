Gem::Specification.new do |s|
  s.name = %q{dm-persevere-adapter}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ivan R. Judson"]
  s.date = %q{2009-02-19}
  s.description = %q{A DataMapper Adapter for persevere}
  s.email = ["irjudson [a] gmail [d] com"]
  s.extra_rdoc_files = ["README.txt", "LICENSE.txt", "TODO", "History.txt"]
  s.files = ["History.txt", "LICENSE.txt", "Manifest.txt", "README.txt", "Rakefile", "TODO", "lib/persevere_adapter.rb", "lib/persevere_adapter/version.rb", "spec/integration/persevere_adapter_spec.rb", "spec/spec.opts", "spec/spec_helper.rb", "tasks/install.rb", "tasks/spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/USERNAME/dm-persevere-adapter}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dm-persevere-adapter}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A DataMapper Adapter for persevere}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
  
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core~> , [">= 0.9.10"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<dm-core~>, [">= 0.9.10"])
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<dm-core~>, [">= 0.9.10"])
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end
