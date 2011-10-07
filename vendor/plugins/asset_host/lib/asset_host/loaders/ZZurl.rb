module AssetHost::Loaders
  # needed by Paperclip::Upfile
  require 'mime/types'
  require 'net/http'
  require 'cgi'
  
  class ZZurl < AssetHost::Loaders::Base
    attr_reader :source, :id
    
    def self.valid?(url)
      #if url =~ /^http.*\.(?:jpg|jpeg|png|gif)$/
      if url =~ /^http/
        # FIXME: opened this up to allow for images with no extension...  need some way to test that this really is an image
        # it's an image...
        return self.new(url)
      else
        return nil
      end
    end

    #----------

    def initialize(url)
      puts "in ZZUrl init"
      @source = "URL"
      @id = url
    end
    
    #----------
    
    def load
      puts "in load for #{@id}"
      
      @id =~ /\/(.+)$/
      file = $~[1]

      # create asset
      a = ::Asset.new(
        :title => file,
        :caption => '',
        :owner => '',
        :image_taken => '',
        :url => @id,
        :notes => "Fetched from URL: #{@id}"
      )
      
      # add image
      a.image = self.image_file
      
      # force _grab_dimensions to run early so that we can load in EXIF
      a.image._grab_dimensions()

      [
        ['title','image_title'],
        ['caption','image_description'],
        ['owner','image_copyright']
      ].each {|f| a[f[0]] = a[f[1]] }
      
      # save Asset
      a.save
      
      return a
    end
    
    #----------
    
    def image_file
      @image_file ||= self._image_file()
    end
    
    def _image_file
      if !self.id
        return nil
      end
      
      raw = nil
      
      uri = URI.parse(self.id)
      Net::HTTP.start(uri.host) {|http|
        raw = http.get(uri.path).body
      }
      
      f = Tempfile.new("IAfromurl",:encoding => 'ascii-8bit')
      f << raw
      return f
    end
    
    #----------
    
  end

end

