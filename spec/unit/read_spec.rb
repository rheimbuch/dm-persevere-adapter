$LOAD_PATH << File.dirname(__FILE__)

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe 'A Persevere adapter' do

  before do
    @adapter = DataMapper::Repository.adapters[:default]
  end

  # describe 'when getting one resource' do
  # 
  #   describe 'if the resource exists' do
  # 
  #     before do
  #       book_xml = <<-BOOK
  #       <?xml version='1.0' encoding='UTF-8'?>
  #       <book>
  #         <author>Stephen King</author>
  #         <created-at type='datetime'>2008-06-08T17:03:07Z</created-at>
  #         <id type='integer'>1</id>
  #         <title>The Shining</title>
  #         <updated-at type='datetime'>2008-06-08T17:03:07Z</updated-at>
  #       </book>
  #       BOOK
  #       @id = 1
  #       @response = mock(Net::HTTPResponse)
  #       @response.stub!(:body).and_return(book_xml)
  #       @adapter.stub!(:http_get).and_return(@response)
  #     end
  # 
  #     it 'should return the resource' do
  #       book = Book.get(@id)
  #       book.should_not be_nil
  #       book.id.should be_an_instance_of(Fixnum)
  #       book.id.should == 1
  #     end
  # 
  #     it 'should do an HTTP GET' do
  #       @adapter.should_receive(:http_get).with('/books/1.xml').and_return(@response)
  #       Book.get(@id)
  #     end
  # 
  #     it "it be equal to itself" do
  #       Book.get(@id).should == Book.get(@id)
  #     end
  #   end
  # 
  # 
  #   describe 'if the resource does not exist' do
  #     it 'should return nil' do
  #       @id = 1
  #       @response = mock(Net::HTTPNotFound)
  #       @response.stub!(:content_type).and_return('text/html')
  #       @response.stub!(:body).and_return('<html></html>')
  #       @adapter.stub!(:http_get).and_return(@response)
  #       id = 4200
  #       Book.get(id).should be_nil
  #     end
  #   end
  # end
  # 
  # describe 'when getting all resource of a particular type' do
  #   before do
  #     books_xml = <<-BOOK
  #     <?xml version='1.0' encoding='UTF-8'?>
  #     <books type='array'>
  #       <book>
  #         <author>Ursula K LeGuin</author>
  #         <created-at type='datetime'>2008-06-08T17:02:28Z</created-at>
  #         <id type='integer'>1</id>
  #         <title>The Dispossed</title>
  #         <updated-at type='datetime'>2008-06-08T17:02:28Z</updated-at>
  #       </book>
  #       <book>
  #         <author>Stephen King</author>
  #         <created-at type='datetime'>2008-06-08T17:03:07Z</created-at>
  #         <id type='integer'>2</id>
  #         <title>The Shining</title>
  #         <updated-at type='datetime'>2008-06-08T17:03:07Z</updated-at>
  #       </book>
  #     </books>
  #     BOOK
  #     @response = mock(Net::HTTPResponse)
  #     @response.stub!(:body).and_return(books_xml)
  #     @adapter.stub!(:http_get).and_return(@response)
  #   end
  # 
  #   it 'should get a non-empty list' do
  #     Book.all.should_not be_empty
  #   end
  # 
  #   it 'should receive one Resource for each entity in the XML' do
  #     Book.all.size.should == 2
  #   end
  # 
  #   it 'should do an HTTP GET' do
  #     @adapter.should_receive(:http_get).and_return(@response)
  #     Book.first
  #   end
  # end
end
