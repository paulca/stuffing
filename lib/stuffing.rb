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
      
      database = options[:database] || "#{File.basename(RAILS_ROOT)}_#{RAILS_ENV}"
      host = options[:host] || 'localhost'
      port = options[:port] || 5984
      couchdb_id = options[:id] || ":class-:id"
      
      class_eval %Q[
        def couchdb
          @connection ||= CouchRest.new("http://#{host}:#{port}")
          @database ||= @connection.database!('#{database}')
        end
        
        def couchdb_content
          #{method_name}.stringify_keys!
        end
        
        def couchdb_id
          interpolate "#{couchdb_id}"
        end
        ]
      
      class_eval do
        
        def interpolate(string)
          string.scan(/:([a-zA-Z_]*)/).flatten.each do |match|
            string = string.gsub(":#{match}",send(match).to_s)
          end
          string
        end
        
        # def couchdb_id
        #   "#{self.class}-#{id}"
        # end
        
        define_method(method_name) do
          begin
            @stuffing ||= new_record? ? {} : couchdb.get(send("couchdb_id"))
          rescue RestClient::ResourceNotFound
            {}
          end
        end
        
        define_method("#{method_name}=") do |args|
          @stuffing = couchdb_content.deep_merge(args.stringify_keys)
        end
        
        def get_stuffing
          @stuffing = couchdb.get(couchdb_id)
        end
        
        def create_stuffing
          couchdb.save({'_id' => couchdb_id}.merge(couchdb_content))
          get_stuffing
        end
        
        def update_stuffing
          record = couchdb_content.merge({'_id' => couchdb_id, '_rev' => couchdb_content['_rev']})
          couchdb.save(record)
          get_stuffing
        end
        
        def destroy_stuffing
          couchdb.delete(couchdb_content)
        end

      end
    end
  end
end