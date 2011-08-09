module AssetHost
  module Paperclip
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def treat_as_image_asset(name)
        include InstanceMethods
        
        define_method "grab_dimensions_for_#{name}" do
          if self.send("#{name}").dirty?
            # need to extract dimensions from the attachment
            self.attachment_for(name)._grab_dimensions
          end
        end
        
        # register our event handler
        self.send("before_save", :"grab_dimensions_for_#{name}")
        
        ::Paperclip.interpolates "sprint", do |attachment,style_name|
          sprint = nil
          if style_name == :original
            sprint = 'original'
          else
            ao = attachment.instance.output_by_style(style_name)

            if ao
              sprint = ao.fingerprint
            else
              ::Paperclip.log("[EWR] Doh! Style path before style fingerprint")
              return nil
            end
          end
          
          return sprint
        end
      end

      module InstanceMethods

      end      
    end
  end
    
  #----------

  class ResqueJob
    @queue = :paperclip
  
    def self.perform(instance_klass, instance_id, attachment_name, *style_args)
      instance = instance_klass.constantize.find(instance_id)
      instance.send(attachment_name).reprocess!(*style_args)
    end
  end

end

module Paperclip
  class Attachment
    
    # Overwrite styles loader to allow caching despite dynamic loading
    def styles
      if !@normalized_styles
        @normalized_styles = ActiveSupport::OrderedHash.new
        @styles.call(self).each do |name, args|
          @normalized_styles[name] = Paperclip::Style.new(name, args.dup, self)
        end
      end
      @normalized_styles
    end
    
    def enqueue_styles(styles)
      Resque.enqueue(AssetHost::ResqueJob,self.instance.class.name,self.instance.id,self.name,styles)
    end
    
    #----------
    
    def trueurl(style_name = default_style, use_timestamp = @use_timestamp)
      url = original_filename.nil? ? interpolate(@default_url, style_name) : interpolate(@options[:trueurl], style_name)
      use_timestamp && updated_at ? [url, updated_at].compact.join(url.include?("?") ? "&" : "?") : url
    end
    
    #----------
        
    def width(style = default_style)
      if !self.instance_read("width")
        return nil
      end
      
      if s = self.styles[style]
        # load dimensions
        if ao = self.instance.output_by_style(style)
          return ao.width
        else
          # TODO: Need to add code to guess dimensions if we don't yet have an output
          g = Paperclip::Geometry.parse(s.processor_options[:size])       
          if g.modifier == '#'
            # match w/h from style
            return g.width.to_i
          end 

          factor = self._compute_style_ratio(s)
          width = ((self.instance_read("width") || 0) * factor).round
          return width < self.instance_read("width") ? width : self.instance_read("width")
        end
      end

      nil
    end
    
    #----------
    
    def height(style = default_style)
      if !self.instance_read("height")
        return nil
      end

      if s = self.styles[style] 
        # load dimensions
        if ao = self.instance.output_by_style(style)
          return ao.height
        else
          # TODO: Need to add code to guess dimensions if we don't yet have an output  
          g = Paperclip::Geometry.parse(s.processor_options[:size])       
          if g.modifier == '#'
            # match w/h from style
            return g.width.to_i
          end 

          factor = self._compute_style_ratio(s)
          height = ((self.instance_read("height") || 0) * factor).round
          
          return height < self.instance_read("height") ? height : self.instance_read("height")
                  
        end
      end

      nil
    end
    
    #----------
    
    def isPortrait?
      w = self.instance_read("width")
      h = self.instance_read("height")
      
      (h > w) ? true : false
    end
    
    #----------
    
    def _compute_style_ratio(style)
      w = self.instance_read("width")
      h = self.instance_read("height")
      
      if !w || !h
        return 0
      end
      
      g = Paperclip::Geometry.parse(style.processor_options[:size])
      ratio = Paperclip::Geometry.new( g.width/w, g.height/h )
      
      # we need to compute off the smaller number
      factor = (ratio.width > ratio.height) ? ratio.height : ratio.width
      
      return factor
    end
    
    #----------
    
    def tags(args = {})
      tags = {}
      
      self.styles.each do |style,v|
        tags[style] = self.tag(style,args)
      end
      
      return tags
    end
    
    #----------

    def tag(style = default_style,args={})
      s = self.styles[style.to_sym]
      
      if !s
        return nil
      end
      
      htmlargs = args.collect { |k,v| %Q!#{k}="#{v}"! }.join(" ")
      
      return %Q(<img src="#{self.url(style)}" width="#{self.width(style)}" height="#{self.height(style)}" alt="#{self.instance.title}" #{htmlargs}/>).html_safe
    end
        
    #----------
    
    def _grab_dimensions
      Paperclip.log("[ewr] grabbing dimensions for #{@queued_for_write[:original]}")

      return unless @queued_for_write[:original]
      
      begin
        p = MiniExiftool.new(@queued_for_write[:original].path)
      rescue
        Paperclip.log("[ewr] Failed to call MiniExifTool")
        return false
      end
      
      instance_write(:width,p.image_width)
      instance_write(:height,p.image_height)
      instance_write(:title,p.title)
      instance_write(:description,p.description)
      instance_write(:copyright,p.copyright)
      instance_write(:taken,p.datetime_original)
      
      true
      
      # TODO: now compute what we have for styles
    end
  end

  class AssetThumbnail < Paperclip::Thumbnail
    attr_accessor :prerender
    attr_accessor :output
    attr_accessor :asset
    
    def initialize file, options = {}, attachment = nil
      @prerender = options[:prerender]
      @size = options[:size]
      @output = options[:output]
      @asset = attachment ? attachment.instance : nil
      
      Paperclip.log("asset is #{@asset} -- output is #{@output}")
      
      super
            
      @convert_options = [ 
        "-gravity #{ @asset.image_gravity || "Center" }", "-strip", "-quality 70", @convert_options 
      ].flatten.compact
      
      Paperclip.log("[ewr] Convert options are #{@convert_options}")
    end
    
    # Perform processing, if prerender == true or we've had to render 
    # this output before. Afterward, delete our old AssetOutput entry if 
    # it exists
    def make
      # do we have an AssetOutput already?
      ao = @asset.outputs.where(:output_id => @output).first

      Paperclip.log("[ewr] make for #{@output} -- ao is #{ ao }")
      dst = nil

      if @prerender || ao
        tmpao = nil
        if !ao 
          # register empty AssetObject to denote processing
          ao = @asset.outputs.create(:output_id => @output)
          Paperclip.log("[ewr] Created tmpao to note processing for #{@output}")
        end
        
        if @size =~ /(\d+)?x?(\d+)?([\#>])?$/ && $~[3] == "#"
          # crop...  scale using dimensions as minimums, then crop to dimensions
          scale = "-scale #{$~[1]}x#{$~[2]}^"
          crop = "-crop #{$~[1]}x#{$~[2]}+0+0"
          
          @convert_options = [@convert_options.shift,scale,crop,@convert_options].flatten
        else
          # don't crop
          scale = "-scale '#{$~[1]}x#{$~[2]}#{$~[3]}'"
          Paperclip.log("[ewr] calling scale of #{scale}")
          @convert_options = [scale,@convert_options].flatten
        end
        
        # call thumbnail generator
        dst = super
        
        # need to get dimensions
        width = height = nil
        begin
          Paperclip.log("Calling geo.from_file for #{dst.path}")
          geo = Geometry.from_file dst.path
          width = geo.width.to_i
          height = geo.height.to_i
          Paperclip.log("geo run was successful -- #{width}x#{height}")
        rescue NotIdentifiedByImageMagickError => e
          # hmmm... do nothing?
        end
        
        # get fingerprint
        print = Digest::MD5.hexdigest(dst.read)
        dst.rewind if dst.respond_to?(:rewind)
        
        ao.attributes = { :fingerprint => print, :width => width, :height => height }
        ao.save
      end
            
      return dst
    end
  end
end