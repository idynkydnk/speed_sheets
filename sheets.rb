require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Google Sheets API Ruby Quickstart'.freeze
CREDENTIALS_PATH = 'credentials.json'.freeze
TOKEN_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

def load_sheets(sheet_id)
  # Initialize the API
  service = Google::Apis::SheetsV4::SheetsService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authorize

  spreadsheet_id = sheet_id
  range = 'Games!A:F'
  response = service.get_spreadsheet_values(spreadsheet_id, range)
  response.values.each do |row|
    x = Game.new
    #date = sheet[row, 1]
    #new_date = Time.new(date[6..9], date[0..1], date[3..4])
    #x.date = new_date
    x.date = row[0]
    x.location = row[1] 
    x.winner1 = row[2]
    x.winner2 = row[3]
    x.loser1 = row[4]
    x.loser2 = row[5]
    if x.location != nil && x.winner1 != nil && x.winner2 != nil && x.loser1 != nil && x.loser2 != nil 
      x.winner1, x.winner2 = x.winner2, x.winner1 if x.winner2 < x.winner1 
      x.loser1, x.loser2 = x.loser2, x.loser1 if x.loser2 < x.loser1 
      x.save
    end
  end
end