source "http://rubygems.org"
gem "sinatra"
gem "data_mapper"
#gem "dm-sqlite-adapter"
gem 'rack'

group :production do
    gem 'pg', '~> 0.18.4'
    gem "dm-postgres-adapter"
end

group :development, :test do
    gem "sqlite3"
    gem "dm-sqlite-adapter"
end