require 'ostruct'
require 'couchrest'
module Stuffing
  def self.included(base) 
    base.extend StuffingMethod
  end

  module StuffingMethod

    def stuffing(*args)
      
      after_create :create_stuffing
      after_update :update_stuffing
      after_destroy :destroy_stuffing
      
      method_name = (args.first.kind_of?(Symbol) or args.first.kind_of?(String)) ? args.first : :stuffing
      options = args.first.kind_of?(Hash) ? args.first : args[1]
      options ||= {}
      
      database = options[:database] || "#{File.basename(RAILS_ROOT)}_#{RAILS_ENV}"
      host = options[:host] || 'localhost'
      port = options[:port] || 5984
      couchdb_id = options[:id] || ":class-:id"
      
      class_eval %Q[
        def couchdb
          @connection ||= CouchRest.new(interpolate("http://#{host}:#{port}"))
          @database ||= @connection.database!(interpolate('#{database}'))
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
          string.scan(/:([a-zA-Z_\.]*)/).flatten.each do |match|
            if !match.empty?
              if match.include?('.')
                begin
                  object = self
                  match.split('.').each do |method|
                    object = object.send(method)
                  end
                  string = string.gsub(":#{match}", "#{object}")
                rescue NoMethodError
                  string = string.gsub(":#{match.split('.').first}",send(match.split('.').first).to_s) 
                end
              else
                string = string.gsub(":#{match}",send(match).to_s) 
              end
            end
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
        
        define_method("stuffing_method_name") do
          method_name
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
          begin
            record = couchdb_content.merge({'_id' => couchdb_id, '_rev' => couchdb_content['_rev']})
            couchdb.save(record)
          rescue RestClient::RequestFailed
            couchdb.save(couchdb_content.merge({'_id' => couchdb_id}))
          end
          get_stuffing
        end
        
        def destroy_stuffing
          couchdb.delete(couchdb_content)
        end
        
        def respond_to?(*args)
          if args.first.to_s[0,8] == "#{stuffing_method_name}" and args.first.to_s[-17,17] != '_before_type_cast'
            return true
          else
            super
          end
        end
        
        def method_missing(method_name, *args)
          if method_name.to_s[0,9] == "#{stuffing_method_name}_"
            item = method_name.to_s.gsub("#{stuffing_method_name}_",'')
            if item.last == '='
              send("#{stuffing_method_name}")[item[0,item.size - 1].to_s] = args.first
            else
              send("#{stuffing_method_name}")[item]
            end
          else
            super
          end
        end

      end
    end
  end
end

if Object.const_defined?("ActiveRecord")
  ActiveRecord::Base.send(:include, Stuffing)
end
