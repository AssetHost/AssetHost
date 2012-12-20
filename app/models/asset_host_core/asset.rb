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
    
    attr_accessible :title, :owner, :url, :caption, :notes, :image_gravity, :image_taken, :is_hidden

    default_scope includes(:outputs)

    scope :visible, where(:is_hidden => false)

    has_many :outputs, :class_name => "AssetOutput", :order => "created_at desc", :dependent => :destroy
    belongs_to :native, :polymorphic => true

  	has_attached_file :image, Rails.application.config.assethost.paperclip_options.merge({
  	  :styles       => Proc.new { Output.paperclip_sizes },
  	  :processors   => [:asset_thumbnail],
  	  :interpolator => self 
  	})

    treat_as_image_asset :image
    
    after_commit :publish_asset_update, :if => :persisted?
    after_commit :publish_asset_delete, :on => :destroy

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
      @s_outputs ||= self.outputs.inject({}) { |h,o| h[o.output.code] = o; h }
      @s_outputs[style.to_s] || false
    end

    def rendered_outputs
      @rendered ||= Output.paperclip_sizes.collect do |s|
        ["#{s[0]} (#{self.image.width(s[0])}x#{self.image.height(s[0])})",s[0]]
      end    
    end
    
    #----------
    
    def self.interpolate(pattern,attachment,style)
      # we support: 
      # global:
      #   :rails_root -- Rails.root
      #
      # style-based:
      #   :style -- output code
      #   :extension -- extension for Output
      # 
      # asset-based:
      #   :id -- asset id
      #   :fingerprint -- image fingerprint
      #
      # output-based:
      #   :sprint -- AssetOutput fingerprint
      
      # first see what we've been passed as a style. could be string, symbol, 
      # Output or AssetOutput
      
      ao = nil
      output = nil
      asset = attachment.instance
            
      result = pattern.clone
      
      if style.respond_to?(:to_sym) && style.to_sym == :original
        # special case...        
      elsif style.is_a? AssetOutput
        ao = style
        output = ao.output
      elsif style.is_a? Output
        output = style
        ao = attachment.instance.outputs.where(:output_id => output).first

        if !ao
          return nil
        end
      else
        output = Output.where(:code => style).first

        if !output
          return nil
        end
        
        ao = attachment.instance.outputs.where(:output_id => output).first
      end
      
      # global rules
      result.gsub!(":rails_root",Rails.root.to_s)
      
      if asset
        # asset-based rules
        result.gsub!(":id",asset.id.to_s)
        result.gsub!(":fingerprint",asset.image_fingerprint)
      else
        if pattern =~ /:(?:id|fingerprint)/
          return false
        end
      end
      
      if style.respond_to?(:to_sym) && style.to_sym == :original
        # hardcoded handling for the original file
        result.gsub!(":style","original")
        result.gsub!(":extension",File.extname(attachment.original_filename).gsub(/^\.+/, ""))
        result.gsub!(":sprint","original")
      else
        if output
          # style-based rules
          result.gsub!(":style",output.code.to_s)
          result.gsub!(":extension",output.extension)        
        else
          if pattern =~ /:(?:style|extension)/
            return false
          end
        end


        if ao && ao.fingerprint
          # output-based rules
          result.gsub!(":sprint",ao.fingerprint)
        else
          result.gsub!(":sprint","NOT_YET_RENDERED")
        end        
      end
      
      return result
        
    end
    
    #----------
    
    private 
    def publish_asset_update
      AssetHostCore::Engine.redis_publish :action => "UPDATE", :id => self.id
      return true
    end
    
    def publish_asset_delete
      AssetHostCore::Engine.redis_publish :action => "DELETE", :id => self.id
      return true
    end
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
