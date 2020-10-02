require_relative 'game'
require_relative 'vollisgame'

class Player
  include DataMapper::Resource
  property :id, Serial
  property :player, Text, :required => true
end

get '/players' do
  @players = Player.all
  erb :players
end

get '/add_player' do
  @players = Player.all
  erb :add_player
end

get '/delete_all_players' do
  @players = Player.all
  @players.each do |player|
    player.destroy
  end
  erb :delete_all_players
end

get '/import_all_players' do
  @games = Game.all :order => :id.desc
  @number_of_games = 100
  add_players_all_games
  erb :import_all_players
end

post '/add_player' do
  n = Player.new
  n.player = params[:player]
  n.save
  redirect '/add_player'
end

get '/player/delete/:id' do
  n = Player.get params[:id]
  n.destroy
  redirect '/all_players'
end

def add_players_all_games
  players = []
  @games[0..@number_of_games].each do |game|
    players << game.winner1 unless players.include?(game.winner1)
    players << game.winner2 unless players.include?(game.winner2)
    players << game.loser1 unless players.include?(game.loser1) 
    players << game.loser2 unless players.include?(game.loser2) 
  end
  players.each do |player|
    n = Player.new
    n.player = player
    n.save
  end
end