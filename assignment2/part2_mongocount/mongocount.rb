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

class DailyInfo
   include MongoMapper::Document
   key :date, Date
   key :ip, String
   key :count, Integer
end

get '/' do
   @today = "#{Date.today}"
   ip = "#{request.ip}"
   DailyInfo.create!({:date=>"#{@today}", :ip=>"#{ip}", :count=>1}).save
   @dailyinfos = DailyInfo.all(:order => :date.desc)
   @dates = @dailyinfos.uniq{|object| object.date}
   @dates.each do |eachdate|
     eachdate.count = @dailyinfos.count{|object| object.date==eachdate.date}
   end
   haml :hello
end
