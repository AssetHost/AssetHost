class Asset < ActiveRecord::Base
  @queue = :paperclip
  
  VIA_UNKNOWN = 0
  VIA_FLICKR = 1
  VIA_LOCAL = 2
  VIA_UPLOAD = 3
  		
	define_index do
    indexes title
    indexes caption
    indexes notes
    has created_at
    has updated_at
  end
  
  GRAVITY_OPTIONS = [
    [ "Center (default)", "Center"    ],
    [ "Top",              "North"     ],
    [ "Bottom",           "South"     ],
    [ "Left",             "West"      ],
    [ "Right",            "East"      ],
    [ "Top Left",         "NorthWest" ],
    [ "Top Right",        "NorthEast" ],
    [ "Bottom Left",      "SouthWest" ],
    [ "Bottom Right",     "SouthEast" ]
  ]
  
  scope :visible, where(:is_hidden => false)
  
  has_many :outputs, :class_name => "AssetOutput", :order => "created_at desc", :dependent => :destroy
  		
	has_attached_file :image, 
	  :styles => Proc.new { Output.paperclip_sizes },
	  :processors => [:asset_thumbnail],
	  :storage => :filesystem,
	  :path => AssetHostSecrets[:path],
	  :trueurl => AssetHostSecrets[:trueurl],
	  :url => AssetHostSecrets[:url],
	  :use_timestamp => false
	  
  treat_as_image_asset :image
	process_in_background :image
		    
  #----------
  
  def json
    { 
      :id         => self.id, 
      :title      => self.title, 
      :caption    => self.caption,
      :owner      => self.owner, 
      :size       => [self.image_width,self.image_height].join('x'), 
      :sizes      => Output.paperclip_sizes.inject({}) { | h, (s,v) | h[s] = { :width => self.image.width(s), :height => self.image.height(s) }; h },
      :tags       => self.image.tags,
      :urls       => Output.paperclip_sizes.inject({}) { |h, (s,v)| h[s] = self.image.url(s); h },
      :url        => "http://#{ASSET_SERVER}/api/assets/#{self.id}/",
      :notes      => self.notes,
      :created_at => self.created_at,
      :taken_at   => self.image_taken || self.created_at
    }
  end
  
  #----------
  
  def Asset.find_or_import(url)
    if asset = AssetImporter.import(url)
      return asset
    else
      return nil
    end    
  end
  
  #----------
  
  def isPortrait?
    ( self.image_width >= self.image_height ) ? false : true
  end
  
  #----------
  
  def url_domain 
    if !self.url
      return nil
    end
    
    domain = URI.parse(self.url).host
    
    return (domain == 'www.flickr.com') ? 'Flickr' : domain
  end
  
  #----------
  
  def output_by_style(style)
    outputs = self.outputs.inject({}) do |h,o|
      h[o.output.code] = o
      h
    end
    
    outputs[style.to_s] || false
  end
  
  def rendered_outputs
    @rendered ||= Output.paperclip_sizes.collect do |s|
      ["#{s[0]} (#{self.image.width(s[0])}x#{self.image.height(s[0])})",s[0]]
    end    
  end
  
  #----------
  
end
