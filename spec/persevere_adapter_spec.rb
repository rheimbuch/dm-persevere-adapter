require File.dirname(__FILE__) + '/spec_helper'


require DataMapper.root / 'lib' / 'dm-core' / 'spec' / 'adapter_shared_spec'

describe DataMapper::Adapters::PersevereAdapter do
  before :all do
    # This needs to point to a valid ldap server
    @adapter = DataMapper.setup(:default, { :adapter => 'persevere',
                                :host => 'localhost',
                                :port => '8080'
                                })

  end

  it_should_behave_like 'An Adapter'

end
