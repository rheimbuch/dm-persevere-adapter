require 'pathname'
require 'rubygems'
require 'hoe'

ROOT    = Pathname(__FILE__).dirname.expand_path
JRUBY   = RUBY_PLATFORM =~ /java/
WINDOWS = Gem.win_platform?
SUDO    = (WINDOWS || JRUBY) ? '' : ('sudo' unless ENV['SUDOLESS'])

require ROOT + 'lib/persevere_adapter/version'

# define some constants to help with task files
GEM_NAME    = 'dm-persevere-adapter'
GEM_VERSION = DataMapper::PersevereAdapter::VERSION

Hoe.spec(GEM_NAME) do |p|
  p.developer('Ivan R. Judson', 'irjudson [a] gmail [d] com')

  p.description = 'A DataMapper Adapter for persevere'
  p.summary = 'A DataMapper Adapter for persevere'
  p.url = 'http://github.com/USERNAME/dm-persevere-adapter'

  p.clean_globs |= %w[ log pkg coverage ]
  p.spec_extras = {
    :has_rdoc => true,
    :extra_rdoc_files => %w[ README.txt LICENSE.txt TODO History.txt ]
  }

  p.extra_deps = [
    ['dm-core', "~> 0.9.10"],
    ['extlib', "~> 0.9.10"],
    ['persevere', "~> 1.0.0"]
  ]

end

Pathname.glob(ROOT.join('tasks/**/*.rb').to_s).each { |f| require f }
