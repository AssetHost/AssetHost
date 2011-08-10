module AssetHostSecrets
  def self.[](key)
    unless @config
      raw_config = File.read("#{Rails.root}/config/secrets.yml")
      @config = YAML.load(raw_config)[Rails.env].symbolize_keys
    end
    @config[key]
  end

  def self.[]=(key, value)
    @config[key.to_sym] = value
  end
end

# -- now define our secrets -- #

FLICKR_API_KEY = AssetHostSecrets[:flickr_api_key]
ASSET_SERVER = AssetHostSecrets[:asset_server]    

