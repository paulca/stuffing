require File.dirname(__FILE__) + '/spec_helper'

class Booja < ActiveRecord::Base
  stuffing
end

describe Booja do
  before do
    CouchRest.new('http://localhost:5984').database!('plugins_test').delete!
    @booja = Booja.new
  end
  
  it "should have a default stuffing of an empty Hash" do
    @booja.stuffing.should == {}
  end
  
  it "should be able to set the stuffing" do
    @booja.stuffing = {:name => 'hello'}
    @booja.stuffing.should == {'name' => 'hello'}
  end
  
  it "should give me the database" do
    @booja.couchdb.should be_a_kind_of(CouchRest::Database)
  end
  
  it "should give me the database" do
    @booja.couchdb.name.should == 'plugins_test'
  end
  
  it "should save the record to CouchDB" do
    @booja.save
    CouchRest.new('http://localhost:5984').database('plugins_test').get("Booja-#{@booja.id}").keys.should == ['_rev', '_id']
  end
  
  describe "updating" do
    before do
      @booja = Booja.new
      @booja.stuffing = {:this => 'that'}
      @booja.save
      @new_booja = Booja.find(@booja.id)
      @new_booja.update_attributes(:stuffing => {:this => 'another'})
    end
    
    it "should have the right id" do
      @booja.couchdb_id.should == 'Booja-1'
    end
    
    it "should find the booja" do
      @found_booja = Booja.find(@booja.id)
      @found_booja.stuffing['this'].should == 'another'
      CouchRest.new('http://localhost:5984').database('plugins_test').get("Booja-#{@booja.id}")['this'].should == 'another'
    end
    
    it "should delete the booja" do
      @new_booja.destroy
      lambda {CouchRest.new('http://localhost:5984').database('plugins_test').get("Booja-#{@booja.id}")}.should raise_error(RestClient::ResourceNotFound)
    end
  end
end

class Baja < ActiveRecord::Base
  stuffing :contents, :id => ":class-:id-:locale"
  attr_accessor :locale
  def self.table_name
    'boojas'
  end
end

describe Baja do
  before do
    @baja = Baja.new
    @baja.locale = 'en'
  end
  
  it "should respond to contents, and not stuffing" do
    lambda { @baja.stuffing }.should raise_error(NoMethodError)
  end
  
  it "should have a contents method" do
    @baja.should respond_to(:contents)
  end
  
  it "should have a generic id first" do
    @baja.couchdb_id.should == "Baja--en"
  end

  it "should have its own id" do
    @baja.save
    @baja.couchdb_id.should == "Baja-1-en"
  end
end

class Banja < ActiveRecord::Base
  stuffing :id => "this_would_be_silly"
  attr_accessor :locale
  def self.table_name
    'boojas'
  end
end

describe Banja do
  before do
    @banja = Banja.new
  end
  
  it "should still work without specifying a method name" do
    @banja.couchdb_id.should == 'this_would_be_silly'
  end
end

class Bonja < ActiveRecord::Base
  stuffing :id => ":bill.ball"
  def self.table_name
    'boojas'
  end
  
  def bill
    OpenStruct.new(:ball => 'tickle')
  end
end

describe Bonja do
  before do
    @bonja = Bonja.new
  end
  
  it "should still work without specifying a method name" do
    @bonja.couchdb_id.should == 'tickle'
  end
end

class Binja < ActiveRecord::Base
  stuffing :id => ":bill.ball-:site.title"
  def self.table_name
    'boojas'
  end
  
  def bill
    "sweet"
  end
  
  def site
    OpenStruct.new(:title => 'yay')
  end
end

describe Binja do
  before do
    @binja = Binja.new
  end
  
  it "should still work if the method doesn't exist" do
    @binja.couchdb_id.should == 'sweet.ball-yay'
  end
  
  it "should allow me to set variables in forms" do
    @binja.stuffing_title = 'whoop!'
    @binja.stuffing['title'].should == 'whoop!'
  end
  
  it "should allow me to create a new binja" do
    Binja.create({:stuffing_tree => 'birch'}).should be_a_kind_of(Binja)
  end
  
  it "shouldn't have a type cast nonsense" do
    @binja.respond_to?('stuffing_before_type_cast').should == false
  end

end

class Bahoja < ActiveRecord::Base
  def self.table_name
    'boojas'
  end  
end

describe Bahoja, "creating a couch record when the activerecord exists, but the couch doc doesn't" do
  before do
    @bajoha = Bahoja.create
    @binja = Binja.find(@bajoha.id)
  end
  
  it "should let me find it by binja" do
    @binja.created_at.to_date.should == @bajoha.created_at.to_date
  end
  
  it "should let me update the binja" do
    @binja.stuffing_banana = 'banana!'
    lambda { @binja.save }.should_not raise_error
  end
end