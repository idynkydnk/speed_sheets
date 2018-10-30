class Player
  include DataMapper::Resource
  property :id, Serial
  property :player, Text, :required => true
end

get '/all_players' do
  @players = Player.all
  erb :all_players
end