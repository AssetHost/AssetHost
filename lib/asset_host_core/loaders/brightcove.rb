module AssetHostCore::Loaders
  # needed by Paperclip::Upfile
  require 'mime/types'
  require 'brightcove-api'
  
  class Brightcove < AssetHostCore::Loaders::Base
    attr_reader :source, :id
    
    def self.valid?(url)
      #if url =~ /flickr\.com\/photos\/[\w@]+\/(\d+)/
      #  # photo page url.  $~[1] is photoid
      #  return self.new($~[1])
      #elsif url =~ /static\.flickr\.com\/\d+\/(\d+)_[\w\d]+/
      #  # photo url. $~[1] is photoid
      #  return self.new($~[1])
      #else
        return nil
      #end
    end

    #----------

    def initialize(videoid)
      puts "in Brightcove init"
      @source = "Brightcove"
      @id = videoid
    end
    
    #----------
    
    def load
      puts "in load for #{@id}"
      
      brightcove = ::Brightcove::API.new( Rails.application.config.assethost.brightcove )
      
      begin
        # get our video info
        response = brightcove.get("find_video_by_id", { :video_id => @id })
      rescue
        # invalid video...
        return nil
      end
      
      resp = response.parsed_response
      
      w = h = 0
      
      resp['renditions'].each do |r|
        if r['frameWidth'] > w
          w = r['frameWidth']
          h = r['frameHeight']
        end
      end
      
      # create asset
      a = AssetHostCore::Asset.new(
        :title => resp["name"],
        :caption => resp["shortDescription"],
        :owner => AssetHostSecrets[:byline],
        :image_taken => DateTime.strptime(resp["publishedDate"],"%Q"),
        :url => nil,
        :notes => "Brightcove import as ID #{resp['id']}"
      )
      
      self.file = resp['videoStillURL']
      
      # add image
      a.image = self.image_file
      
      # now create our BrightcoveVideo native object
      native = AssetHostCore::BrightcoveVideo.new(
        :videoid => resp['id'],
        :length => resp['length']
      )
      
      native.save()
      
      a.native = native
      
      # save Asset
      a.save()
      
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
      
      f = Tempfile.new("IABrightcove",:encoding => 'ascii-8bit')
      f << raw
      return f
    end
    
    #----------
    
  end
end

