require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'google_drive'
require_relative 'game'
require_relative 'player'
require_relative 'vollisgame'
require_relative 'sheets'

configure :development do
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db") 
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
end
 
DataMapper.finalize.auto_upgrade!

def load_all_sheets
  sheet_id_2011 = "1QP5ot-2S-eakqIyFPJ5mDI4QB0CLuy-HV_ttYCSI0Xg"
  sheet_id_2016 = "1gvdN0KvpSOz7hV_OKoJKBerwynMKboBnQvHRsbcc4sQ"
  sheet_id_2017 = "1lI5GMwYa1ruXugvAERMJVJO4pX5RY69DCJxR4b0zDuI"
  #sheet_id_2018 = "12wLVculr9WQa1NIphWHPijQ3vwE2BbXTjK7N_owvq40"
  load_sheets(sheet_id_2011)
  load_sheets(sheet_id_2016)
  load_sheets(sheet_id_2017)
  #load_sheets(sheet_id_2018)
end

def my_time_now
  month = Time.now.month.to_s
  day = Time.now.day.to_s
  year = Time.now.year.to_s
  month = "0" + month if month.length < 2
  day = "0" + day if day.length < 2
  return month + "/" + day + "/" + year
end

def delete_database
  Game.destroy
end

def todays_stats
  name_and_stats = [] 
  games = todays_games
  players = todays_players(games)
  players.each do |player|
    wins, losses, score = 0, 0, 0
    games.each do |game|
      if player == game.winner1 || player == game.winner2
        wins += 1
        if game.score
          score += calculate_differential(game.score)
        end
      elsif player == game.loser1 || player == game.loser2
        losses += 1
        if game.score
          score -= calculate_differential(game.score)
        end
      end
    end
    win_percent = "%.2f" % (wins.to_f / (wins + losses).to_f * 100.0)
    x = { :player => player, :wins => wins, :losses => losses, 
          :win_percentage => win_percent, :score => score }
    name_and_stats.push(x)
  end
  name_and_stats.sort_by! { |a| a[:score].to_i}
  name_and_stats.sort_by! { |a| a[:win_percentage].to_f}
  name_and_stats.reverse
end

def calculate_differential score
  if score[2] == "-"
    return score[0..1].to_i - score[3..4].to_i
  elsif score.to_i > 18
    return 2
  else
    return 21 - score.to_i
  end
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

def games_in_year(year)
  games = []
  @games.each do |game|
    if game.date[6..9].to_s == year.to_s
      games << game 
    end
  end
  return games
end

def all_years
  years = []
  @games.each do |game|
    if years.include?(game.date[6..9])
    else
      years << game.date[6..9]
    end
  end
  return years
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
    name_and_stats << x unless x[:total_games] < @min_games || x[:total_games] >= @max_games
  end
  name_and_stats.sort_by! { |a| [a[:win_percentage].to_f, a[:wins], a[:losses]] }
  name_and_stats.reverse
end

def past_years_stats games
  name_and_stats = []
  players = all_players
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
    total_games = wins + losses
    x = { :player => player, :wins => wins, :losses => losses, 
          :win_percentage => win_percent, :total_games => total_games }
    name_and_stats << x unless x[:total_games] < @min_games || x[:total_games] >= @max_games
  end
  name_and_stats.sort_by! { |a| [a[:win_percentage].to_f, a[:wins], -a[:losses]] }
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