
require_relative 'player'
require_relative 'vollisgame'
require_relative 'golfgame'

class Game
  include DataMapper::Resource
  property :id, Serial
  property :location, Text, :required => true
  property :winner1, Text, :required => true
  property :winner2, Text, :required => true
  property :loser1, Text, :required => true
  property :loser2, Text, :required => true
  property :score, Text
  property :date, Text
  property :updated_at, DateTime
end

get '/' do
  @games = Game.all :order => :id.desc
  @year = Time.now.year.to_s
  this_year_games = games_in_year(@year)
  @games = this_year_games
  @todays_stats = todays_stats
  @min_games = 1
  @max_games = 20
  @years_stats = years_stats
  @min_games = 20
  @max_games = 99999
  @min_years_stats = years_stats
  erb :stats
end

get '/year' do
  @games = Game.all :order => :id.desc
  @years = all_years - [Time.now.year.to_s]
  erb :year
end

get '/pastyear/:year' do |year|
  @year = year
  @games = Game.all :order => :id.desc
  games = games_in_year(year)
  @min_games = 1
  @max_games = 20
  @years_stats = past_years_stats(games)
  @min_games = 20
  @max_games = 99999
  @min_years_stats = past_years_stats(games)
  erb :pastyear
end

get '/past_years' do
  #delete_database
  #load_all_sheets
  @games = Game.all :order => :id.desc
  @years = all_years - [Time.now.year.to_s]
  @past_years_stats = {}
  @min_past_years_stats = {}
  @min_games = 1
  @max_games = 20
  @years.each do |year|
    games = games_in_year(year)
    @past_years_stats[year] = past_years_stats(games)
  end

  @min_games = 20
  @max_games = 2000
  @years.each do |year|
    games = games_in_year(year)
    @min_past_years_stats[year] = past_years_stats(games)
  end

  erb :past_years
end

get '/players/:player/:year' do
  @player = params[:player]
  @year = params[:year]
  @games = Game.all :order => :id.desc
  this_year_games = games_in_year(@year)
  @games = this_year_games
  @team_stats = team_stats
  @min_games = 1
  @max_games = 10
  @player_stats = player_stats
  @opponent_stats = opponent_stats
  @min_games = 10
  @max_games = 10000
  @min_player_stats = player_stats
  @min_opponent_stats = opponent_stats
  erb :player_stats
end

get '/allyears/:player' do |player|
  @player = params[:player]
  @games = Game.all :order => :id.desc
  @team_stats = team_stats
  @min_games = 1
  @max_games = 10
  @player_stats = player_stats
  @opponent_stats = opponent_stats
  @min_games = 10
  @max_games = 10000
  @min_player_stats = player_stats
  @min_opponent_stats = opponent_stats
  erb :player_stats
end

get '/players/:player' do |player|
  @games = Game.all :order => :id.desc
  @player_years = all_years
  @years = []
  @player = player
  @player_years.each do |year|
    @games = Game.all :order => :id.desc
    this_year_games = games_in_year(year)
    @games = this_year_games
    @team_stats = team_stats
    @min_games = 1
    @max_games = 10000
    @player_stats = player_stats
    if @player_stats.length > 1
      @years << year
    end
  end
  remove_absent_years(player)
  erb :player
end

get '/top_teams' do
  @min_games = 10
  @games = Game.all :order => :id.desc
  this_year_games = games_in_year(Time.now.year.to_s)
  @games = this_year_games
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
  this_year_games = games_in_year(Time.now.year.to_s)
  @games = this_year_games
  @todays_games = todays_games
  @min_games = 1
  @max_games = 20
  @years_stats = years_stats
  @min_games = 20
  @max_games = 99999
  @min_years_stats = years_stats
  #delete_all_players
  #import_all_players(300)
  players = []
  @players = Player.all :order => :updated_at.desc
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
  n.score = params[:score]
  n.date = my_time_now 
  n.updated_at = Time.now
  n.winner1, n.winner2 = n.winner2, n.winner1 if n.winner2 < n.winner1 
  n.loser1, n.loser2 = n.loser2, n.loser1 if n.loser2 < n.loser1 
  if n.location != "" && n.winner1 != "" && n.winner2 != "" && n.loser1 != "" && n.loser2 != "" && n.score != ""
    add_player(n.winner1)
    add_player(n.winner2)
    add_player(n.loser1)
    add_player(n.loser2)
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
  @players = Player.all :order => :updated_at.desc
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
  n.score = params[:score]
  n.winner1, n.winner2 = n.winner2, n.winner1 if n.winner2 < n.winner1 
  n.loser1, n.loser2 = n.loser2, n.loser1 if n.loser2 < n.loser1 
  if n.location != "" && n.winner1 != "" && n.winner2 != "" && n.loser1 != "" && n.loser2 != "" && n.score != ""
    n.save
  end
  redirect '/add_game'
end

get '/:id/delete' do
  @game = Game.get params[:id]
  @title = "Confirm deletion of game ##{params[:id]}"
  erb :delete
end

delete '/:id' do
  n = Game.get params[:id]
  n.destroy
  redirect '/edit_games'
end