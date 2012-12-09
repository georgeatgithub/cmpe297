require 'rubygems'
require 'sinatra'
require 'haml'
require 'mongo_mapper'


configure do  
  host = JSON.parse(ENV['VCAP_SERVICES'])['mongodb-2.0'].first['credentials']['hostname'] rescue 'localhost'
  port = JSON.parse(ENV['VCAP_SERVICES'])['mongodb-2.0'].first['credentials']['port'] rescue 27017
  database = JSON.parse( ENV['VCAP_SERVICES'] )['mongodb-2.0'].first['credentials']['db'] rescue 'tutorial_db'
  username = JSON.parse( ENV['VCAP_SERVICES'] )['mongodb-2.0'].first['credentials']['username'] rescue nil
  password = JSON.parse( ENV['VCAP_SERVICES'] )['mongodb-2.0'].first['credentials']['password'] rescue nil  
  uri = "mongodb://#{username}:#{password}@#{host}:#{port}/#{database}"
  
  MongoMapper.database = database
end

class DateInfo
   include MongoMapper::Document
   key :date, Date
   key :ip, String
   key :count, Integer

   distribution 
   def self.map
     <<-MAP
       function() {
         emit(this.date, 1);
       }
     MAP
   end
  
   def self.reduce
     <<-REDUCE
       function(k, v) {
         var count = 0;
         for (index in v) {
           count += v[index];
         }
         return count
       }
      REDUCE
    end

   def self.build
      db.collection.mapReduce(
	map, 
	reduce,
	{ out: "map_reduce is used" }
	)
   end
end

get '/' do
   @today = "#{Date.today}"
   ip = "#{request.ip}"
   DateInfo.create!({:date=>"#{@today}", :ip=>"#{ip}", :count=>1}).save
   @day = DateInfo.build.find()
   haml :hello
end
