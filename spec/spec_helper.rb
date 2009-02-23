require 'pathname'
require 'rubygems'

gem 'rspec', '~>1.1.11'
require 'spec'

require Pathname(__FILE__).dirname.expand_path.parent + 'lib/persevere_adapter'

DataMapper.setup(:default, {
  :adapter => 'persevere',
  :host => 'localhost',
  :port => '8080',
  :uri => 'http://localhost:8080'
})

#
# I need to make the Book class for Books to relate to
#

class Book
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :author, String
  property :created_at, DateTime
  property :title, String
end