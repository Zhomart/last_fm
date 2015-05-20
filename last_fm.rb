require 'pry'
require 'json'
require 'restclient'
require 'yaml/store'
require 'colorize'
require 'digest'

# Simple last fm client that uses last.fm's desktop API.
#
# Currently it gets only top tracks of given user
#
class LastFM
  API_ROOT = "http://ws.audioscrobbler.com/2.0/"
  HEADERS = { 'User-Agent' => 'MySimpleScript/0.1.0' }

  attr_reader :api_key, :api_secret
  attr_reader :token

  def initialize(api_key, api_secret)
    @api_key = api_key
    @api_secret = api_secret
    @cache_store = YAML::Store.new("cache.yml")

    @cache_store.transaction do
      @token = @cache_store['token']
    end
  end

  def gen_token!
    url = api_url("auth.gettoken")
    response_raw = RestClient.get(url, HEADERS)
    response = JSON.parse(response_raw)
    @token = response['token']

    @cache_store.transaction do
      @cache_store['token'] = @token
    end

    @token
  end

  def has_token?
    !!@token
  end

  def get_auth_url
    gen_token! unless @token

    "http://www.last.fm/api/auth/?api_key=#{api_key}&token=#{@token}"
  end

  def get_top_tracks(limit = 50)
    url = api_url("user.gettoptracks", user: "mukhamejanov", limit: limit)

    response_raw = RestClient.get(url, HEADERS)
    response = JSON.parse(response_raw)

    response['toptracks']['track']
  end

  #
  # @param name - playlist name
  # @param tracks - array of hashes in format { 'name' => "Magia", 'artist' => { 'name' => 'Kalafina' } }
  #
  def create_playlist!(name, tracks)
    list = tracks.map do |track|
      "#{track['artist']['name']} - #{track['name']}"
    end

    FileUtils.mkdir_p("playlists")

    file = "playlists/#{name}.dat"
    File.open(file, 'w') do |f|
      f.write(list.join("\n"))
      puts "Playlist [#{list.size} tracks] is saved to #{file}".green
    end
  end

  private

  def api_url(method_name, params = {})
    params = params.merge(method: method_name, api_key: api_key, format: 'json')

    "#{API_ROOT}?#{hash_to_url_params(params)}"
  end

  def hash_to_url_params(params)
    params.to_a.map { |r| r.join('=') }.join('&')
  end

  def api_signature(method_name)
    md5 = Digest::MD5.new
    md5 << "api_key#{api_key}"
    md5 << method_name
    md5 << "token#{token}"

    md5.hexdigest
  end

end
