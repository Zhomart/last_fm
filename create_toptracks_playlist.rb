require 'pry'
require 'colorize'
require 'dotenv'

require './last_fm'

Dotenv.load

last_fm = LastFM.new(ENV['API_KEY'], ENV['API_SECRET'])

puts last_fm.create_playlist!("my_top_tracks", last_fm.get_top_tracks(500))
