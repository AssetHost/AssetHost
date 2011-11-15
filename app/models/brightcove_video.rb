class BrightcoveVideo < Video
  has_one :asset
  
  def attrs
    {
      "data-assethost"  => "BrightcoveVideo",
      "data-ah-videoid" => self.videoid
    }
  end
end