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
  stuffing :contents
  def self.table_name
    'boojas'
  end
end

describe Baja do
  before do
    @baja = Baja.new
  end
  
  it "should respond to contents, and not stuffing" do
    lambda { @baja.stuffing }.should raise_error(NoMethodError)
  end
  
  it "should have a contents method" do
    @baja.should respond_to(:contents)
  end
end