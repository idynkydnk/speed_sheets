require_relative 'game'
require_relative 'vollisgame'

class Player
  include DataMapper::Resource
  property :id, Serial
  property :player, Text, :required => true
  property :updated_at, DateTime
end

get '/players' do
  @players = Player.all :order => :updated_at.desc
  erb :players
end

get '/add_player' do
  @players = Player.all :order => :updated_at.desc
  erb :add_player
end

get '/delete_all_players' do
  delete_all_players
  erb :delete_all_players
end

get '/import_all_players' do
  import_all_players(300)
  erb :import_all_players
end

post '/add_player' do
  add_player(params[:player])
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

def add_player new_player
  if player_exists?(new_player)
    @players = Player.all :order => :updated_at.desc
    @players.each do |player|
      if player.player == new_player
        player.updated_at = Time.now
        player.save
        return
      end
    end
    return
  end
  n = Player.new
  n.player = new_player
  n.updated_at = Time.now
  n.save
end

def player_exists? new_player
  @players = Player.all :order => :updated_at.desc
  @players.each do |player|
    if player.player == new_player
      return true
    end
  end
  return false
end

def move_to_top new_player
  @players = Player.all :order => :updated_at.desc
  n = 0
  @players.each do |player|
    player.id = player.id + n
    if player.player == new_player
      n = 1
      player.id = 1242
    end
    puts player.player
    puts player.id
  end
end


def add_players name1, name2, name3, name4
  @players = Player.all :order => :updated_at.desc
  all_players = []
  new_players = []
  @players.each do |player|
    all_players << player.player
  end
  new_players << name1 unless all_players.include?(name1)
  new_players << name2 unless all_players.include?(name2)
  new_players << name3 unless all_players.include?(name3)
  new_players << name4 unless all_players.include?(name4)
  new_players.each do |new_player|
    n = Player.new
    n.player = new_player
    n.save
  end
end

def delete_all_players
  @players = Player.all :order => :updated_at.desc
  @players.each do |player|
    player.destroy
  end
end

def import_all_players number_of_games_back
  @games = Game.all :order => :id.desc
  players = []
  @games[0..number_of_games_back].each do |game|
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



