
require_relative 'player'
require_relative 'vollisgame'

class Game
  include DataMapper::Resource
  property :id, Serial
  property :location, Text, :required => true
  property :winner1, Text, :required => true
  property :winner2, Text, :required => true
  property :loser1, Text, :required => true
  property :loser2, Text, :required => true
  property :date, Text
  property :updated_at, DateTime
end

get '/' do
  @games = Game.all :order => :id.desc
  @todays_stats = todays_stats
  @min_games = 1
  @max_games = 14
  @years_stats = years_stats
  @min_games = 20
  @max_games = 99999
  @min_years_stats = years_stats
  erb :stats
end

get '/players/:player' do |player|
  @games = Game.all
  @min_games = 5
  @team_stats = team_stats
  @player = player
  @player_stats = player_stats
  @opponent_stats = opponent_stats
  erb :player_stats
end

get '/top_teams' do
  @min_games = 10
  @games = Game.all
  @all_stats = team_stats
  @top_teams = top_teams
  erb :top_teams
end

get '/team_stats' do
  @games = Game.all :order => :id.desc
  @min_games = 10
  @team_stats = team_stats
  erb :team_stats
end

get '/add_game' do
  @games = Game.all :order => :id.desc
  @players = Player.all
  players = []
  @players.each do |player|
    players << player.player
  end
  @players = players
  @todays_stats = todays_stats
  erb :add_game
end

post '/add_game' do
  n = Game.new
  n.location = "TK"
  n.winner1 = params[:winner1]
  n.winner2 = params[:winner2]
  n.loser1 = params[:loser1]
  n.loser2 = params[:loser2]
  n.date = my_time_now 
  n.updated_at = Time.now
  n.winner1, n.winner2 = n.winner2, n.winner1 if n.winner2 < n.winner1 
  n.loser1, n.loser2 = n.loser2, n.loser1 if n.loser2 < n.loser1 
  if n.location != "" && n.winner1 != "" && n.winner2 != "" && n.loser1 != "" && n.loser2 != "" 
    n.save
  end
  redirect '/add_game'
end

get '/games' do
  @games = Game.all :order => :id.desc
  erb :games
end

get '/edit_games' do
  @games = Game.all :order => :id.desc
  erb :edit_games
end

get '/:id' do
  @players = Player.all
  players = []
  @players.each do |player|
    players << player.player
  end
  @players = players
  @game = Game.get params[:id]
  @title = "Edit game ##{params[:id]}"
  erb :edit
end

put '/:id' do
  n = Game.get params[:id]
  n.location = "TK"
  n.winner1 = params[:winner1]
  n.winner2 = params[:winner2]
  n.loser1 = params[:loser1]
  n.loser2 = params[:loser2]
  #n.updated_at = Time.now
  if n.location != "" && n.winner1 != "" && n.winner2 != "" && n.loser1 != "" && n.loser2 != "" 
    n.save
  end
  redirect '/'
end

get '/:id/delete' do
  @game = Game.get params[:id]
  @title = "Confirm deletion of game ##{params[:id]}"
  erb :delete
end

delete '/:id' do
  n = Game.get params[:id]
  n.destroy
  redirect '/games'
end