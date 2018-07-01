require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'google_drive'

configure :development do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db") 
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
end

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

class Player
  include DataMapper::Resource
  property :id, Serial
  property :player, Text, :required => true
end
 
DataMapper.finalize.auto_upgrade!

get '/' do
  @games = Game.all :order => :id.desc
  @min_games = 2
  @todays_stats = todays_stats
  @years_stats = years_stats
  erb :stats
end

get '/reload_database' do
  "disabled"
  #delete_database
  #reload_database
  #{}"reloaded"
end

get '/delete_database' do
  "disabled"
  #delete_database
  #"deleted"
end

def reload_database
  session = GoogleDrive::Session.from_config("config.json")
  sheet = session.spreadsheet_by_key("1lI5GMwYa1ruXugvAERMJVJO4pX5RY69DCJxR4b0zDuI").worksheets[0]
  (1..sheet.num_rows).each do |row|

    x = Game.new
    #date = sheet[row, 1]
    #new_date = Time.new(date[6..9], date[0..1], date[3..4])
    #x.date = new_date
    x.date = sheet[row, 1]
    x.location = sheet[row, 2] 
    x.winner1 = sheet[row, 3]
    x.winner2 = sheet[row, 4]
    x.loser1 = sheet[row, 5]
    x.loser2 = sheet[row, 6]
    x.save
  end 
end

get '/all_players' do
  @players = Player.all
  erb :all_players
end

get '/players/:player' do |player|
  @games = Game.all
  @min_games = 1
  @team_stats = team_stats
  @player = player
  @player_stats = player_stats
  @opponent_stats = opponent_stats
  erb :player_stats
end

get '/players/no_kyle/:player' do |player|
  @games = Game.all
  @team_stats = no_kyle_team_stats
  @player = player
  @player_stats = player_stats
  @opponent_stats = no_kyle_opponent_stats
  erb :player_stats
end

get '/no_kyle' do
  @games = Game.all :order => :id.desc
  @no_kyle_stats = no_kyle_stats
  erb :no_kyle
end

get '/top_teams' do
  @min_games = 2
  @games = Game.all
  @all_stats = team_stats
  @top_teams = top_teams
  erb :top_teams
end

get '/team_stats' do
  @games = Game.all :order => :id.desc
  @min_games = 2
  @team_stats = team_stats
  erb :team_stats
end

get '/add_game' do
  @games = Game.all :order => :id.desc
  @todays_stats = todays_stats
  erb :add_game
end

get '/add_player' do
  @players = Player.all
  erb :add_player
end

post '/add_player' do
  n = Player.new
  n.player = params[:player]
  puts n.player
  n.save
  redirect '/add_player'
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

def my_time_now
  month = Time.now.month.to_s
  day = Time.now.day.to_s
  year = Time.now.year.to_s
  month = "0" + month if month.length < 2
  day = "0" + day if day.length < 2
  return month + "/" + day + "/" + year
end

get '/:id' do
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
  name_and_stats.sort_by! { |a| a[:win_percentage].to_f}
  name_and_stats.reverse
end

def todays_games
  games = []
  @games.each do |game|
    if game.date[0..1].to_i == Time.now.month &&
        game.date[3..4].to_i == Time.now.day &&
        game.date[6..9].to_i == Time.now.year
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
    players << game.winner1 unless players.include?(game.winner1)
    players << game.winner2 unless players.include?(game.winner2)
    players << game.loser1 unless players.include?(game.loser1) 
    players << game.loser2 unless players.include?(game.loser2) 
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
    name_and_stats << x unless x[:total_games] < @min_games
  end
  name_and_stats.sort_by! { |a| a[:win_percentage].to_f}
  name_and_stats.reverse
end

def no_kyle_stats
  name_and_stats = [] 
  players = all_players
  players.each do |player|
    wins, losses = 0, 0
    @games.each do |game|
      if game.winner1 == "Kyle Thomson" ||
          game.winner2 == "Kyle Thomson" ||
          game.loser1 == "Kyle Thomson" ||
          game.loser2 == "Kyle Thomson"
        next
      end
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
    name_and_stats.push(x) unless total_games < 5
  end
  name_and_stats.sort_by! { |a| a[:win_percentage].to_f}
  name_and_stats.reverse
end

def teams
  all_teams = []
  @games.each_with_index do |game, x|
    team = game.winner1 + " and " + game.winner2 
    if all_teams.include?(team) 
    else
      all_teams << team
    end
    team = game.loser1 + " and " + game.loser2 
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

def no_kyle_team_stats
  stats = []
  all_teams = teams
  all_teams.each do |team|
    wins, losses = 0, 0
    @games.each do |game|
      if game.winner1 == "Kyle Thomson" ||
          game.winner2 == "Kyle Thomson" ||
          game.loser1 == "Kyle Thomson" ||
          game.loser2 == "Kyle Thomson"
        next
      end
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
    stats.push(x) unless total_games == 0
  end
  stats.sort! { |a,b| a[:team] <=> b[:team] }
end

def top_teams
  stats = []
  @all_stats.each do |stat|
    stats << stat unless stat[:total_games] < @min_games
  end
  x = format_teams(stats)
  x.sort_by! { |a| a[:win_percentage].to_f}
  x.reverse
end

def format_teams(stats)
  formatted_team = []
  stats.each do |stat|
    players = stat[:team].split(" and ")
    stat[:player1] = players[0]
    stat[:player2] = players[1]
    formatted_team << stat
  end
end

def player_stats
  stats = []
  @team_stats.each do |stat|
    if stat[:team].include?(@player)
      stats << stat unless stat[:total_games] < @min_games
    end
  end
  x = format_teamates(@player, stats)
  x.sort_by! { |a| a[:win_percentage].to_f}
  x.reverse
end

def format_teamates(player, stats)
  formatted_team = []
  stats.each do |stat|
    players = stat[:team].split(" and ")
    player == players[0] ? partner = players[1] : partner = players[0]
    stat[:team] = partner
    formatted_team << stat
  end
end

def all_player_games
  players_games = []
  @games.each do |game|
    if game.winner1 == @player ||
        game.winner2 == @player ||
        game.loser1 == @player ||
        game.loser2 == @player  
      players_games << game
    end
  end
end

def opponent_stats
  stats = [] 
  player_games = all_player_games
  all_players.each do |opponent|
    wins, losses = 0, 0
    player_games.each do |game|
      if game.winner1 == @player ||
          game.winner2 == @player
        if game.loser1 == opponent ||
            game.loser2 == opponent
          wins += 1
        end 
      end
      if game.loser1 == @player ||
          game.loser2 == @player
        if game.winner1 == opponent ||
            game.winner2 == opponent
          losses += 1
        end 
      end
    end
    win_percent = "%.2f" % (wins.to_f / (wins + losses).to_f * 100.0)
    total_games = wins + losses
    x = { :opponent => opponent, :wins => wins, :losses => losses, 
          :win_percentage => win_percent, :total_games => total_games }
    stats.push(x) unless total_games < @min_games
  end
  stats.sort_by! { |a| a[:win_percentage].to_f}
  stats.reverse
end

def no_kyle_opponent_stats
  stats = [] 
  player_games = all_player_games
  all_players.each do |opponent|
    wins, losses = 0, 0
    player_games.each do |game|
      if game.winner1 == "Kyle Thomson" ||
          game.winner2 == "Kyle Thomson" ||
          game.loser1 == "Kyle Thomson" ||
          game.loser2 == "Kyle Thomson"
        next
      end
      if game.winner1 == @player ||
          game.winner2 == @player
        if game.loser1 == opponent ||
            game.loser2 == opponent
          wins += 1
        end 
      end
      if game.loser1 == @player ||
          game.loser2 == @player
        if game.winner1 == opponent ||
            game.winner2 == opponent
          losses += 1
        end 
      end
    end
    win_percent = "%.2f" % (wins.to_f / (wins + losses).to_f * 100.0)
    total_games = wins + losses
    x = { :opponent => opponent, :wins => wins, :losses => losses, 
          :win_percentage => win_percent, :total_games => total_games }
    stats.push(x) unless total_games == 0
  end
  stats.sort! { |a,b| b[:total_games] <=> a[:total_games] }
end
