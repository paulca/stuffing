require 'ostruct'
require 'couchrest'
module Stuffing
  def self.included(base) 
    base.extend StuffingMethod
  end

  module StuffingMethod
    def stuffing(method_name = :stuffing, options = {})
      
      after_create :create_stuffing
      after_update :update_stuffing
      after_destroy :destroy_stuffing
      
      class_eval do
        
        @@database = options[:database] || "#{File.basename(RAILS_ROOT)}_#{RAILS_ENV}"
        @@host = options[:host] || 'localhost'
        @@port = options[:port] || 5984
        @@method_name = method_name
        
        def couchdb
          connection = CouchRest.new("http://#{@@host}:#{@@port}")
          connection.database!(@@database)
        end
        
        def couchdb_id
          "#{self.class}-#{id}"
        end
        
        define_method(method_name) do
          @stuffing ||= new_record? ? {} : couchdb.get(couchdb_id)
        end
        
        define_method("#{method_name}=") do |args|
          @stuffing = args
        end
        
        def create_stuffing
          couchdb.save({'_id' => couchdb_id}.merge(send(@@method_name)))
        end

      end
    end
  end
end