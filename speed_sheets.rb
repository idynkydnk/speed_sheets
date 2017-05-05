require 'rubygems'
require 'sinatra'
require 'data_mapper'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")
 
class Game
  include DataMapper::Resource
  property :id, Serial
  property :location, Text, :required => true
  property :winner1, Text, :required => true
  property :winner2, Text, :required => true
  property :loser1, Text, :required => true
  property :loser2, Text, :required => true
  property :date, DateTime
  property :updated_at, DateTime
end
 
DataMapper.finalize.auto_upgrade!

get '/' do
  @games = Game.all :order => :id.desc
  @min_games = 10
  @todays_stats = todays_stats
  @years_stats = years_stats
  erb :stats
end

get '/players/:player' do |player|
  @games = Game.all
  @team_stats = team_stats
  @player = player
  @player_stats = player_stats
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
  @todays_stats = todays_stats
  erb :add_game
end

get '/games' do
  @games = Game.all :order => :id.desc
  erb :games
end

get '/edit_games' do
  @games = Game.all :order => :id.desc
  erb :edit_games
end

post '/add_game' do
  n = Game.new
  n.location = params[:location]
  n.winner1 = params[:winner1]
  n.winner2 = params[:winner2]
  n.loser1 = params[:loser1]
  n.loser2 = params[:loser2]
  n.date = Time.now
  n.updated_at = Time.now
  n.winner1, n.winner2 = n.winner2, n.winner1 if n.winner2 < n.winner1 
  n.loser1, n.loser2 = n.loser2, n.loser1 if n.loser2 < n.loser1 
  if n.location != "" && n.winner1 != "" && n.winner2 != "" && n.loser1 != "" && n.loser2 != "" 
    n.save
  end
  redirect '/add_game'
end

get '/:id' do
  @game = Game.get params[:id]
  @title = "Edit game ##{params[:id]}"
  erb :edit
end

put '/:id' do
  n = Game.get params[:id]
  n.location = params[:location]
  n.winner1 = params[:winner1]
  n.winner2 = params[:winner2]
  n.loser1 = params[:loser1]
  n.loser2 = params[:loser2]
  n.updated_at = Time.now
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

def reload_database
  session = GoogleDrive::Session.from_config("config.json")
  sheet = session.spreadsheet_by_key("1lI5GMwYa1ruXugvAERMJVJO4pX5RY69DCJxR4b0zDuI").worksheets[0]
  (1..sheet.num_rows).each do |row|
    x = Game.new
    date = sheet[row, 1].to_s
    new_date = Time.new(date[6..9], date[0..1], date[3..4])
    x.date = new_date
    x.location = sheet[row, 2] 
    x.winner1 = sheet[row, 3]
    x.winner2 = sheet[row, 4]
    x.loser1 = sheet[row, 5]
    x.loser2 = sheet[row, 6]
    x.save
  end 
end

def delete_database
  Game.destroy
end

def todays_stats
  name_and_stats = [] 
  games = todays_games
  players = todays_players(games)
  players.each do |player|
    wins, losses = 0, 0
    games.each do |game|
      if player == game.winner1 || player == game.winner2
        wins += 1
      elsif player == game.loser1 || player == game.loser2
        losses += 1
      end
    end
    win_percent = "%.2f" % (wins.to_f / (wins + losses).to_f * 100.0)
    x = { :player => player, :wins => wins, :losses => losses, 
          :win_percentage => win_percent }
    name_and_stats.push(x)
  end
  name_and_stats.sort! { |a,b| b[:wins] <=> a[:wins] }
end

def todays_games
  games = []
  @games.each do |game|
    if game.date.strftime("%m/%d/%y") == Time.now.strftime("%m/%d/%y")
      games << game 
    end
  end
  return games
end

def todays_players(games)
  players = []
  games.each do |game|
    players << game.winner1 unless players.include?(game.winner1)
    players << game.winner2 unless players.include?(game.winner2)
    players << game.loser1 unless players.include?(game.loser1)
    players << game.loser2 unless players.include?(game.loser2)
  end
  return players
end


def all_players
  players = []
  @games.each do |game|
    players << game.winner1 unless players.include?(game.winner1) || 
      game.winner1.include?("???")
    players << game.winner2 unless players.include?(game.winner2) || 
      game.winner2.include?("???")
    players << game.loser1 unless players.include?(game.loser1) || 
      game.loser1.include?("???")
    players << game.loser2 unless players.include?(game.loser2) || 
      game.loser2.include?("???")
  end
  return players
end

def years_stats
  name_and_stats = [] 
  players = all_players
  players.each do |player|
    wins, losses = 0, 0
    @games.each do |game|
      if player == game.winner1 || player == game.winner2
        wins += 1
      elsif player == game.loser1 || player == game.loser2
        losses += 1
      end
    end
    win_percent = "%.2f" % (wins.to_f / (wins + losses).to_f * 100.0)
    total_games = wins + losses
    x = { :player => player, :wins => wins, :losses => losses, 
          :win_percentage => win_percent, :total_games => total_games }
    name_and_stats.push(x) unless x[:total_games] < @min_games
  end
  name_and_stats.sort! { |a,b| b[:win_percentage] <=> a[:win_percentage] }
end

def teams
  all_teams = []
  @games.each_with_index do |game, x|
    team = game.winner1 + " and " + game.winner2 
    if all_teams.include?(team) 
    else
      all_teams << team
    end
  end
  all_teams.sort! { |a,b| a <=> b }
end

def team_stats
  stats = []
  all_teams = teams
  all_teams.each do |team|
    wins, losses = 0, 0
    @games.each do |game|
      if team == game.winner1 + " and " + game.winner2
        wins += 1
      elsif team == game.loser1 + " and " + game.loser2
        losses += 1
      end
    end
    win_percent = "%.2f" % (wins.to_f / (wins + losses).to_f * 100.0)
    total_games = wins + losses
    x = { :team => team, :wins => wins, :losses => losses, 
          :win_percentage => win_percent, :total_games => total_games }
    stats.push(x)
  end
  stats.sort! { |a,b| a[:team] <=> b[:team] }
end

def top_teams
  stats = []
  @all_stats.each do |stat|
    if stat[:total_games] > @min_games
      stats << stat
    end
  end
  stats.sort! { |a,b| b[:win_percentage] <=> a[:win_percentage] }
end

def player_stats
  stats = []
  @team_stats.each do |stat|
    if stat[:team].include?(@player)
      stats << stat 
    end
  end
  x = format_teamates(@player, stats)
  x.sort! { |a,b| b[:total_games] <=> a[:total_games] }
end

def format_teamates(player, stats)
  formatted_team = []
  stats.each do |stat|
    players = stat[:team].split(" and ")
    player == players[0] ? partner = players[1] : partner = players[0]
    stat[:team] = "With " + partner
    formatted_team << stat
  end
end
