class Asset < ActiveRecord::Base
  @queue = :paperclip
  
  VIA_UNKNOWN = 0
  VIA_FLICKR = 1
  VIA_LOCAL = 2
  VIA_UPLOAD = 3
  		
	#define_index do
  #  indexes title
  #  indexes description
  #  has created_at
  #  has updated_at
  #end
  
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
  
  has_many :outputs, :class_name => "AssetOutput", :order => "created_at desc", :dependent => :destroy
  		
	has_attached_file :image, 
	  :styles => Proc.new { Output.paperclip_sizes },
	  :processors => [:asset_thumbnail],
	  :storage => :filesystem,
	  :path => ":rails_root/public/images/:id_:fingerprint_:sprint.:extension",
	  :trueurl => "http://localhost:3000/images/:id_:fingerprint_:sprint.:extension",
	  :url => "http://localhost:3000/i/:fingerprint/:id-:style.:extension",
	  :use_timestamp => false
	  
  treat_as_image_asset :image
	process_in_background :image
		    
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
  
  def rendered_outputs
    @rendered ||= Output.paperclip_sizes.collect do |s|
      ["#{s[0]} (#{self.image.width(s[0])}x#{self.image.height(s[0])})",s[0]]
    end    
  end
  
  #----------
  
end
