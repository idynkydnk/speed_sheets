class Vollisgame
  include DataMapper::Resource
  property :id, Serial
  property :winner, Text, :required => true
  property :loser, Text, :required => true
  property :date, Text
  property :updated_at, DateTime
end

get '/vollis' do
  @vollisgames = Vollisgame.all :order => :id.desc
  @todays_stats = todays_stats
  @min_games = 1
  @max_games = 14
  @years_stats = years_stats
  @min_games = 20
  @max_games = 99999
  @min_years_stats = years_stats
  erb :vollis_stats
end

get '/add_vollis_game' do
  @vollisgames = Vollisgame.all :order => :id.desc
  @players = Player.all
  players = []
  @players.each do |player|
    players << player.player
  end
  @players = players
  @todays_vollis_stats = todays_vollis_stats
  erb :add_vollis_game
end

post '/add_vollis_game' do
  n = Vollisgame.new
  n.winner = params[:winner]
  n.loser = params[:loser]
  n.date = my_time_now 
  n.updated_at = Time.now
  if n.winner != "" && n.loser != "" 
    n.save
  end
  redirect '/add_vollis_game'
end