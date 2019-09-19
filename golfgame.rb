require_relative 'game'
require_relative 'player'

class Golfgame
  include DataMapper::Resource
  property :id, Serial
  property :golfer, Text
  property :location, Text
  property :score, Text
  property :par, Text
  property :date, Text
  property :updated_at, DateTime
end

get '/add_golf_game' do
  @golfgames = Golfgame.all :order => :id.desc
  erb :add_golf_game
end

post '/add_golf_game' do
  n = Golfgame.new
  n.golfer = params[:golfer]
  n.location = params[:location]  
  n.score = params[:score]
  n.par = params[:par]
  n.date = my_time_now 
  n.updated_at = Time.now
  if n.golfer != "" 
    n.save
  end
  redirect '/add_golf_game'
end