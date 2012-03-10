module AssetHostCore
  class BrightcoveVideo < Video
    has_one :asset
    
    def CLASS
      "BrightcoveVideo"
    end
    
    def attrs
      {
        "data-assethost"  => "BrightcoveVideo",
        "data-ah-videoid" => self.videoid
      }
    end
    
    def as_json
      {
        videoid: self.videoid,
        length: self.length,
        flvurl: self.flvurl
      }
    end
  end
end
