require_relative 'game'
require_relative 'player'

class Vollisgame
  include DataMapper::Resource
  property :id, Serial
  property :winner, Text, :required => true
  property :loser, Text, :required => true
  property :date, Text
  property :updated_at, DateTime
end

get '/vollis_stats' do
  @vollisgames = Vollisgame.all :order => :id.desc
  @todays_vollis_stats = todays_vollis_stats
  @min_games = 1
  @max_games = 10
  @years_stats = years_vollis_stats
  @min_games = 10
  @max_games = 99999
  @min_years_stats = years_vollis_stats
  erb :vollis_stats
end

get '/add_vollis_game' do
  @vollisgames = Vollisgame.all :order => :id.desc
  @players = all_vollis_players
  @todays_vollis_stats = todays_vollis_stats
  erb :add_vollis_game
end

post '/add_vollis_game' do
  n = Vollisgame.new
  n.winner = params[:winner1]
  n.loser = params[:loser1]
  n.date = my_time_now 
  n.updated_at = Time.now
  if n.winner != "" && n.loser != "" 
    n.save
  end
  redirect '/add_vollis_game'
end

def todays_vollis_stats
  name_and_stats = [] 
  games = todays_vollis_games
  players = todays_vollis_players(games)
  players.each do |player|
    wins, losses = 0, 0
    games.each do |game|
      if player == game.winner
        wins += 1
      elsif player == game.loser
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

def todays_vollis_games
  games = []
  @vollisgames.each do |game|
    if game.date[0..1].to_i == Time.now.month &&
        game.date[3..4].to_i == Time.now.day &&
        game.date[6..9].to_i == Time.now.year
      games << game 
    end
  end
  return games
end

def todays_vollis_players(games)
  players = []
  games.each do |game|
    players << game.winner unless players.include?(game.winner)
    players << game.loser unless players.include?(game.loser)
  end
  return players
end

def all_vollis_players
  players = []
  @vollisgames.each do |game|
    players << game.winner unless players.include?(game.winner) 
    players << game.loser unless players.include?(game.loser) 
  end
  return players
end

def years_vollis_stats
  name_and_stats = []
  players = all_vollis_players
  players.each do |player|
    wins, losses = 0, 0
    @vollisgames.each do |game|
      if player == game.winner
        wins += 1
      elsif player == game.loser
        losses += 1
      end
    end
    win_percent = "%.2f" % (wins.to_f / (wins + losses).to_f * 100.0)
    total_games = wins + losses
    x = { :player => player, :wins => wins, :losses => losses, 
          :win_percentage => win_percent, :total_games => total_games }
    name_and_stats << x unless x[:total_games] < @min_games || x[:total_games] >= @max_games
  end
  name_and_stats.sort_by! { |a| a[:win_percentage].to_f}
  name_and_stats.reverse
end