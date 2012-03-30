module AssetHostCore
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
      indexes owner
      has created_at
      has updated_at
      where "is_hidden = 0"
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

    default_scope includes(:outputs)

    scope :visible, where(:is_hidden => false)

    has_many :outputs, :class_name => "AssetOutput", :order => "created_at desc", :dependent => :destroy
    belongs_to :native, :polymorphic => true

  	has_attached_file :image, Rails.application.config.assethost.paperclip_options.merge({
  	  :styles => Proc.new { Output.paperclip_sizes },
  	  :processors => [:asset_thumbnail]  	  
  	})

    treat_as_image_asset :image

    #----------
    
    AssetHostCore::Output.all.each do |o|
      define_method o.code do
        self.size(o.code)
      end
    end      
    
    #----------
    
    def size(code)
      if !@_sizes
        @_sizes = {}
      end
      
      @_sizes[ code ] ||= AssetSize.new(self,Output.where(:code => code).first)      
    end

    #----------

    def json(sizes=[])
      sizes = nil
      urls = nil
      tags = nil

      { 
        :id         => self.id, 
        :title      => self.title, 
        :caption    => self.caption,
        :owner      => self.owner, 
        :size       => [self.image_width,self.image_height].join('x'), 
        :sizes      => Output.paperclip_sizes.inject({}) { | h, (s,v) | h[s] = { :width => self.image.width(s), :height => self.image.height(s) }; h },
        :tags       => self.image.tags,
        :urls       => Output.paperclip_sizes.inject({}) { |h, (s,v)| h[s] = self.image.url(s); h },
        :url        => "http://#{Rails.application.config.assethost.server}#{AssetHostCore::Engine.mounted_path}/api/assets/#{self.id}/",
        :notes      => self.notes,
        :created_at => self.created_at,
        :taken_at   => self.image_taken || self.created_at,
        :native     => self.native ? self.native.as_json : nil
      }
    end
    
    def as_json(options={})
      self.json()
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
    
    def tag(style)
      self.image.tag(style)
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
      @s_outputs ||= self.outputs.inject({}) do |h,o|
        h[o.output.code] = o
        h
      end

      @s_outputs[style.to_s] || false
    end

    def rendered_outputs
      @rendered ||= Output.paperclip_sizes.collect do |s|
        ["#{s[0]} (#{self.image.width(s[0])}x#{self.image.height(s[0])})",s[0]]
      end    
    end

    #----------
  end
  
  #----------
  
  class AssetSize
    attr_accessor  :width
    attr_accessor  :height
    attr_accessor  :tag
    attr_accessor :url
    attr_accessor  :asset
    attr_accessor  :output
    
    def initialize(asset,output)
      @asset  = asset
      @output = output
      
      [:width,:height,:tag,:url].each do |a|
        self.send("#{a}=",@asset.image.send(a,output.code_sym))
      end
    end
  end
end
