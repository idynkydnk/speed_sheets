def golf_games_in_year(year)
  games = []
  @games.each do |game|
    if game.date[6..9].to_s == year.to_s
      games << game 
    end
  end
  return games
end

def golfer_stats
	stats = []
	@games.each do |game|
		if @golfer == game.golfer
			stats.push(game)
		end
	end
	return stats
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