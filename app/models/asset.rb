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
    [ "Center (default)",  "Center"    ],
    [ "Top-Middle",        "North"     ],
    [ "Bottom-Middle",     "South"     ],
    [ "Middle-Left",       "West"      ],
    [ "Middle-Right",      "East"      ],
    [ "Top Left",          "NorthWest" ],
    [ "Top Right",         "NorthEast" ],
    [ "Bottom Left",       "SouthWest" ],
    [ "Bottom Right",      "SouthEast" ]
  ]
  
  has_many :outputs, :class_name => "AssetOutput", :order => "created_at desc", :dependent => :destroy
  		
	has_attached_file :image, 
	  :styles => Proc.new { Output.paperclip_sizes },
	  :processors => [:asset_thumbnail],
	  :storage => :filesystem,
	  :path => ":rails_root/public/images/:id_:fingerprint_:sprint.:extension",
	  :trueurl => "/images/:id_:fingerprint_:sprint.:extension",
	  :url => "/i/:fingerprint/:id-:style.:extension",
	  :use_timestamp => false
	  
  treat_as_image_asset :image
	process_in_background :image
		
	validates :idkey, :uniqueness => true, :presence => true, :length => { :minimum => 4 }
    
  #----------
  
  def Asset.find_or_import(url)
    if url =~ /cache.blogdowntown.com\/images\/([\w\-_]+)_\w{1,2}\.jpg/
      return Asset.find($~[1])
    elsif a = Asset.find_by_idkey(url)
      return a
    else
      import = AssetImporter.import(url)

      if import
        asset = Asset.new_with_unique_idkey(
          :idkey => import.photoid,
          :title => import.title,
          :description => import.description,
          :owner => import.owner
        )

        asset.image = import.image_file

        return asset
      else
        return nil
      end
    end
  end
  
  #----------
  
  def Asset.new_with_unique_idkey(params)
    # try this key as is
    if Asset.find_by_idkey(params[:idkey])
      # doh.  need to mix it up
      Asset.new_with_unique_idkey(params.merge({:idkey => params[:idkey] + "-1"}))
    else
      return Asset.new(params)
    end
  end
  
  def Asset.new_via_import(url)
    import = AssetImporter.import(url)
    
    if import
      asset = Asset.new_with_unique_idkey(
        :idkey => import.photoid,
        :title => import.title,
        :description => import.description,
        :owner => import.owner
      )
      
      asset.image = import.image_file
      
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
