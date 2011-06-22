class Asset < ActiveRecord::Base
  
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
		
	has_attached_file :image, 
	  :styles => Proc.new { Output.paperclip_sizes },
	  :storage => :s3,
	  :s3_credentials => "#{Rails.root}/config/s3.yml",
	  :url => ":s3_alias_url",
	  :s3_host_alias => "cache.blogdowntown.com",
	  :path => "/images/:id_:style.:extension"
	  
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
  
end
