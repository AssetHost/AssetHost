module ImageAsset
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
        self.send("before_#{name}_post_process", :"grab_dimensions_for_#{name}")
        
        Paperclip.interpolates "sprint", do |attachment,style_name|
          sprint = nil
          if style_name == :original
            sprint = 'original'
          else
            o = Output.where(:code => style_name)
            ao = attachment.instance.outputs.where(:output_id => o).first

            if ao
              sprint = ao.fingerprint
            else
              Paperclip.log("[EWR] Doh! Style path before style fingerprint")
              return nil
            end
          end
          
          return sprint
        end
    end

    module InstanceMethods

    end      
  end
  
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
    def enqueue_styles(styles)
      Resque.enqueue(ImageAsset::ResqueJob,self.instance.class.name,self.instance.id,self.name,styles)
    end
    
    def trueurl(style_name = default_style, use_timestamp = @use_timestamp)
      url = original_filename.nil? ? interpolate(@default_url, style_name) : interpolate(@options[:trueurl], style_name)
      use_timestamp && updated_at ? [url, updated_at].compact.join(url.include?("?") ? "&" : "?") : url
    end
        
    # TODO: Now that AssetOutput tracks rendered styles, width and height could be cached
    # instead of computing them on each request
    def width(style = default_style)
      if s = self.styles[style]
        # load dimensions
        if ao = self.instance.outputs.where(:output_id => Output.where(:code => style).first).first
          return ao.width
        else
          
        end
        
        #g = Paperclip::Geometry.parse(s.geometry)       
        #if g.modifier == '#'
          # match w/h from style
        #  return g.width.to_i
        #end 
        
        #factor = self._compute_style_ratio(s)
        #return ((self.instance_read("width") || 0) * factor).round
      end

      nil
    end
    
    def height(style = default_style)
      if s = self.styles[style] 
        # load dimensions
        if ao = self.instance.outputs.where(:output_id => Output.where(:code => style).first).first
          return ao.height
        else
          
        end
        
        #g = Paperclip::Geometry.parse(s.geometry)       
        #if g.modifier == '#'
          # match w/h from style
        #  return g.width.to_i
        #end 
        
        #factor = self._compute_style_ratio(s)
        #return ((self.instance_read("height") || 0) * factor).round
      end

      nil
    end
    
    def isPortrait?
      w = self.instance_read("width")
      h = self.instance_read("height")
      
      (h > w) ? true : false
    end
    
    def _compute_style_ratio(style)
      w = self.instance_read("width")
      h = self.instance_read("height")
      
      if !w || !h
        return 0
      end
      
      g = Paperclip::Geometry.parse(style.geometry)
      ratio = Paperclip::Geometry.new( g.width/w, g.height/h )
      
      # we need to compute off the smaller number
      factor = (ratio.width > ratio.height) ? ratio.height : ratio.width
      
      return factor
    end

    def tag(style = default_style,args)
      if !args
        args = {}
      end
      
      s = self.styles[style]
      
      if !s
        return nil
      end
      
      # load dimensions
      width = height = nil
      if ao = self.instance.outputs.where(:output_id => Output.where(:code => style).first).first
        width = ao.width
        height = ao.height
      end
      
      htmlargs = args.collect { |k,v| %Q!#{k}="#{v}"! }.join(" ")
      
      return %Q(<img src="#{self.url(style)}" width="#{width}" height="#{height}" alt="#{self.instance.title}" #{htmlargs}/>).html_safe
    end
    
    def has?(style = default_style)
      if s = self.styles[style]
       factor = self._compute_style_ratio(s)
       return (factor <= 1) 
      end

      nil
    end
    
    def _grab_dimensions
      return unless @queued_for_write[:original]
            
      p = MiniExiftool.new(@queued_for_write[:original].path)
      
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
      @size = options[:size].gsub(">",'')
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
        if !ao || ao.fingerprint?
          # register empty AssetObject to denote processing
          tmpao = @asset.outputs.create(:output_id => @output)
          Paperclip.log("[ewr] Created tmpao to note processing for #{@output}")
        end
        
        if @size =~ /(\d+)?x?(\d+)?(\#)?$/ && $~[3]
          # crop...  scale using dimensions as minimums, then crop to dimensions
          scale = "-scale #{$~[1]}x#{$~[2]}^"
          crop = "-crop #{$~[1]}x#{$~[2]}+0+0"
          
          @convert_options = [@convert_options.shift,scale,crop,@convert_options].flatten
        else
          # don't crop
          scale = "-scale #{$~[1]}x#{$~[2]}"
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
        
        if tmpao
          tmpao.attributes = { :fingerprint => print, :width => width, :height => height }
          tmpao.save
        else
          # create AssetOutput instance
          @asset.outputs.create(:output_id => @output,:fingerprint => print, :width => width, :height => height)        
        end
      end
      
      if ao
        # if we had an AssetOutput instance, delete it
        ao.destroy
      end
      
      return dst
    end
  end
end