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
  end
end
