$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

describe 'A Persevere adapter' do

  before do
    @adapter = DataMapper::Repository.adapters[:default]
  end

  describe 'when saving a resource' do

    before do
      @book = Book.new(:title => 'Hello, World!', :author => 'Anonymous')
    end

    it 'should call the adapter create method' do
      @adapter.should_receive(:create).with([@book])
      @book.save
    end
  end
end
