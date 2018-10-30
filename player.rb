require_relative 'game'
require_relative 'vollisgame'

class Player
  include DataMapper::Resource
  property :id, Serial
  property :player, Text, :required => true
end

get '/all_players' do
  @players = Player.all
  erb :all_players
end

get '/add_player' do
  @players = Player.all
  erb :add_player
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