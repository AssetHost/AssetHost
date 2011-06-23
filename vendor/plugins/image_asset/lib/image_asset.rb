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

        #define_method "#{name}_changed?" do
        #  attachment_has_changed?(name)
        #end
    end

    module InstanceMethods

    end      
  end
end

module Paperclip
  class Attachment
    def width(style = default_style)
      if s = self.styles[style]
        g = Paperclip::Geometry.parse(s.geometry)       
        if g.modifier == '#'
          # match w/h from style
          return g.width.to_i
        end 
        
        factor = self._compute_style_ratio(s)
        return ((self.instance_read("width") || 0) * factor).round
      end

      nil
    end
    
    def height(style = default_style)
      if s = self.styles[style] 
        g = Paperclip::Geometry.parse(s.geometry)       
        if g.modifier == '#'
          # match w/h from style
          return g.width.to_i
        end 
        
        factor = self._compute_style_ratio(s)
        return ((self.instance_read("height") || 0) * factor).round
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

    def tag(style = default_style,*args)
      if !args
        args = {}
      end
      
      s = self.styles[style]
      
      if !s
        return nil
      end
      
      htmlargs = args.collect { |k,v| %Q!#{k}="#{v}"! }.join(" ")
      
      return %Q(<img src="#{self.url(style)}" width="#{self.width(style)}" height="#{self.height(style)}" alt="#{self.instance.title}" #{htmlargs}/>).html_safe
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
      
      #geo = Geometry.from_file(@queued_for_write[:original])
      
      puts "queued is #{@queued_for_write[:original].path}"
      
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
end