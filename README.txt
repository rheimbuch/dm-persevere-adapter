= dm-persevere-adapter

A DataMapper adapter for Persevere (http://www.persvr.org/)

This requires the persevere gem (http://github.com/irjudson/persevere) which provides a ruby interface to Persevere.

== Usage

DM Persevere Adapter is very simple and very similar to the REST
Adapter, however it has two differences: 1) instead of XML it uses
JSON, and 2) Persevere supports typing using JSON Schema. These
differences make it valuable to have a separate DM adapter
specifically for Persevere so it can leverage richer aspects of
persevere.

The setup and resource mapping is identical to standard datamapper
objects, as can be seen below.

DataMapper.setup(:default, {
                   :adapter => 'persevere',
                   :host => 'localhost',
                   :port => '8080'
                 })

class MyUser
  include DataMapper::Resource

  property :id,            Serial
  property :uuid,          String
  property :name,          String
  property :first_name,    String
  property :last_name,     String
  property :groupid,       Integer
  property :userid,        Integer
  property :username,      String
  property :homedirectory, String

end

To use with Rails, you can put this in your environment.rb:
  config.gem "dm-core"
  config.gem "data_objects"
  config.gem "dm-persevere-adapter", :lib => 'persevere_adapter'

With a database.yml:

development: &defaults
  :adapter: persevere
  :host: localhost
  :port: 8080

test:
  <<: *defaults

production:
  <<: *defaults

== Code

# Create
user = MyUser.new(:username => "dmtest", :uuid => UUID.random_create().to_s,
                  :name => "DataMapper Test", :homedirectory => "/home/dmtest",
                  :first_name => "DataMapperTest", :last_name => "User",
                  :userid => 3, :groupid => 500)
user.save

# Retrieve
user = MyUser.first(:netid => 'dmtest')
puts user

# Modify
if user.update_attributes(:name => 'DM Test')
  puts user
else
  puts "Failed to update attributes."
end

# Delete
result = user.destroy
puts "Result: #{result}"

== To Do:

- Make a do-adapter for persevere.
- Finish Query details (limit, order, etc)
- Cleanup Documentation
