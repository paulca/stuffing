require File.dirname(__FILE__) + '/spec_helper'

class Booja < ActiveRecord::Base
  stuffing
end

describe do
  before do
    @booja = Booja.new
    @booja.couchdb.delete!
  end
  
  it "should have a default stuffing of an empty Hash" do
    @booja.stuffing.should == {}
  end
  
  it "should be able to set the stuffing" do
    @booja.stuffing = 'hello'
    @booja.stuffing.should == 'hello'
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
      @booja.couchdb.delete!
      @booja.stuffing = {:this => 'that'}
      @booja.save
    end
    
    it "should find the booja" do
      @found_booja = Booja.find(@booja.id)
      @found_booja.stuffing.keys.should == ['_id', '_rev', 'this']
    end
  end
end