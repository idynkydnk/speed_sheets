require "google_drive"
require "json"

module Enumerable
  def sort_by_frequency
    histogram = inject(Hash.new(0)) { |hash, x| hash[x] += 1; hash}
    sort_by { |x| [histogram[x], x] }
  end
end

class BeachSeason
  attr_accessor :players

  def initialize
    @key = "1lI5GMwYa1ruXugvAERMJVJO4pX5RY69DCJxR4b0zDuI"
    @session = GoogleDrive::Session.from_config("config.json")
    puts @session
    @games_sheet = @session.spreadsheet_by_key(@key).worksheets[0]
    @stats_sheet = @session.spreadsheet_by_key(@key).worksheets[1]
    @team_stats_sheet = @session.spreadsheet_by_key(@key).worksheets[2]
    @top_teams_sheet = @session.spreadsheet_by_key(@key).worksheets[4]
    @players = []
    @name_and_stats = []
  end

  def remove_duplicates(duplicates)
    i = 0
    removed = []
    duplicates.reverse_each do |x|
      if removed.empty?
        removed << x
      elsif x != removed[i] 
        removed << x
        i += 1
      end
    end
    return removed
  end

  def build_players_database
    (1..@games_sheet.num_rows).each do |row|
      (3..@games_sheet.num_cols).each do |col|
          @players << @games_sheet[row,col] 
      end
    end
    @players = @players.sort_by_frequency
    @players = remove_duplicates(@players)
  end

  def build_team_stats
    team_stats_col_1
    team_stats_col_2
    team_stats_wins_and_losses
    @team_stats_sheet.save
  end

  def build_top_teams
    top_teams = []
    temp_top_teams = []
    minimum_number_of_games = 10
    (1..@team_stats_sheet.num_rows).each do |row|
      if @team_stats_sheet[row, 6].to_i >= minimum_number_of_games
        top_teams << [@team_stats_sheet[row, 1], 
                      @team_stats_sheet[row, 2], 
                      @team_stats_sheet[row, 3], 
                      @team_stats_sheet[row, 4],
                      @team_stats_sheet[row, 5],
                      @team_stats_sheet[row, 6]]
      end 
    end
    top_teams.sort_by!{ |x| x[4] }
    top_teams.reverse!
    row = 1
    top_teams.each do |team_row|
      temp_top_teams << team_row
      if temp_top_teams.include?([team_row[1],
                                team_row[0],
                                team_row[2],
                                team_row[3],
                                team_row[4],
                                team_row[5]])
        next
      end

      (1..top_teams.length).each do |col|
       @top_teams_sheet[row, col] = team_row[col - 1] 
      end
      row += 1
    end
    @top_teams_sheet.save
  end

  def build_stats
    @players.each_with_index do |player, index|
      wins = 0
      losses = 0
      @name_and_stats << []
      @name_and_stats[index] << player
      (1..@games_sheet.num_rows).each do |row|
        (3..6).each do |col|
          if col < 5
            if @games_sheet[row, col] == player
              wins += 1
            end
          else
            if @games_sheet[row, col] == player
              losses += 1
            end
          end
        end
      end
      @name_and_stats[index] << wins
      @name_and_stats[index] << losses
    end
    @players.each_with_index do |player,row|
      row += 1
      (1..6).each do |col|
        if col < 4
          @stats_sheet[row, col] = @name_and_stats[row-1][col-1]
        elsif col == 4
          win_percentage = calc_win_percentage(@name_and_stats[row-1][1], @name_and_stats[row-1][2])
          @stats_sheet[row, col] = win_percentage
        end
      end
    end
    @stats_sheet.save
  end

  def top_partners(player)

  end

  private

  def team_stats_col_1
    row = 1
    @players.each do |player|
      @players.length.times do
        @team_stats_sheet[row, 1] = player
        row += 1
      end
    end
  end

  def team_stats_col_2
    row = 1
    @players.length.times do
      @players.each do |player2|
        @team_stats_sheet[row, 2] = player2
        row += 1
      end
    end
  end

  def team_stats_wins_and_losses
    (1..@team_stats_sheet.num_rows).each do |row|
      player1 = @team_stats_sheet[row, 1]
      player2 = @team_stats_sheet[row, 2]
      wins = 0
      losses = 0
      (1..@games_sheet.num_rows).each do |games_row|
        if (@games_sheet[games_row, 3] == player1 && @games_sheet[games_row, 4] == player2) || (@games_sheet[games_row, 3] == player2 && @games_sheet[games_row, 4] == player1)
          wins += 1 
        end
        if (@games_sheet[games_row, 5] == player1 && @games_sheet[games_row, 6] == player2) || (@games_sheet[games_row, 5] == player2 && @games_sheet[games_row, 6] == player1)
          losses += 1 
        end
      end
      @team_stats_sheet[row, 3] = wins
      @team_stats_sheet[row, 4] = losses
      win_percentage = calc_win_percentage(wins, losses)
      @team_stats_sheet[row, 5] = win_percentage
      @team_stats_sheet[row, 6] = (wins + losses)
    end
  end

  def calc_win_percentage(wins, losses)
    total = wins + losses
    if wins == 0
      return wins
    else
      percentage = wins.to_f / total.to_f
      percentage.round(2)
      return percentage
    end
  end
  

end

season_2017 = BeachSeason.new
season_2017.build_players_database
season_2017.build_team_stats
season_2017.build_top_teams
season_2017.build_stats
