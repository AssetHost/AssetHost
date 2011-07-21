module AssetHost::Loaders
  # needed by Paperclip::Upfile
  require 'mime/types'
  
  class Flickr < AssetHost::Loaders::Base
    attr_reader :source, :id
    
    def self.valid?(url)
      if url =~ /flickr\.com\/photos\/[\w@]+\/(\d+)/
        # photo page url.  $~[1] is photoid
        return self.new($~[1])
      elsif url =~ /static\.flickr\.com\/\d+\/(\d+)_[\w\d]+/
        # photo url. $~[1] is photoid
        return self.new($~[1])
      else
        return nil
      end
    end

    #----------

    def initialize(photoid)
      puts "in Flickr init"
      @source = "Flickr"
      @id = photoid
    end
    
    #----------
    
    def load
      puts "in load for #{@id}"
      
      flickr = MiniFlickr.new()
      # we're going to try and go get it from flickr
      p = flickr.call('flickr.photos.getInfo',:photo_id => self.id)["photo"]
      
      if !p
        return nil
      end
            
      sizes = flickr.call('flickr.photos.getSizes',:photo_id => self.id)["sizes"]["size"]
      
      self.file         = sizes[-1]["source"]
      
      # look up licenses
      licenses = flickr.call('flickr.photos.licenses.getInfo')
      
      # find our license
      license = nil
      licenses["licenses"]["license"].each do |l|
        if l['id'] == p['license']
          license = [ l['name'], l['url'] ].join(" : ")
          break
        end
      end

      # create asset
      a = ::Asset.new(
        :title => p["title"]["_content"],
        :description => p["description"]["_content"],
        :owner => p['owner']['realname'] || p['owner']["username"],
        :image_taken => p["dates"]["taken"],
        :url => p['urls']['url'][0]['_content'],
        :notes => license
      )
      
      # add image
      a.image = self.image_file
      
      # save Asset
      a.save
      
      return a
    end
    
    #----------
    
    def image_file
      @image_file ||= self._image_file()
    end
    
    def _image_file
      if !self.file
        self.load
      end
      
      raw = nil
      
      uri = URI.parse(self.file)
      Net::HTTP.start(uri.host) {|http|
        raw = http.get(uri.path).body
      }
      
      f = Tempfile.new("IAFlickr",:encoding => 'ascii-8bit')
      f << raw
      return f
    end
    
    #----------
    
  end

  require 'net/http'
  require 'cgi'
  #require "active_support/json"
  #require 'json'

  class MiniFlickr
    attr :api_key

    def initialize()
    end

    def user()
      USERID
    end

    def call(method, params = {})
      parameters = params.dup
      parameters[:api_key] = FLICKR_API_KEY
      parameters[:method] = method
      parameters[:format] = "json"
      parameters[:nojsoncallback] = 1

      #puts "params: " + path_for_params(parameters)

      response = http.get(path_for_params(parameters))

      # return an object parsed from the JSON    
      ActiveSupport::JSON.decode(response.body)
    end

  private

    def path_for_params(params)
      query_string = "?" + params.inject([]) { |qs, pair| qs << "#{CGI.escape(pair[0].to_s)}=#{CGI.escape(pair[1].to_s)}"; qs }.join("&")
      "/services/rest/" + query_string
    end

    def http
      @http ||= Net::HTTP.new("api.flickr.com", 80)
    end
  end
  
end

