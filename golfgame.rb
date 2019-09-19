require_relative 'game'
require_relative 'player'
require_relative 'golf_functions'

class Golf
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
  @golfgames = Golf.all :order => :id.desc
  erb :add_golf_game
end

post '/add_golf_game' do
  n = Golf.new
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

get '/golfers/:golfer' do |golfer|
  @games = Golf.all :order => :id.desc
  this_year_games = golf_games_in_year(Time.now.year.to_s)
  @games = this_year_games
  @golfer = golfer
  @golfer_stats = golfer_stats
  erb :golfer_stats
end