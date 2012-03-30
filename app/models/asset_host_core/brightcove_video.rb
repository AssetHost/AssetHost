module AssetHostCore
  class BrightcoveVideo < Video
    has_one :asset

    def attrs
      {
        "data-assethost"  => "BrightcoveVideo",
        "data-ah-videoid" => self.videoid
      }
    end
    
    def as_json
      {
        :class    => "BrightcoveVideo"
        :videoid  => self.videoid,
        :length   => self.length
      }
    end
  end
end
