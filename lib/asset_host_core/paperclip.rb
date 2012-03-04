require 'mini_exiftool'

module AssetHostCore
  module Paperclip
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def treat_as_image_asset(name)
        include InstanceMethods
        
        attachment_definitions[name][:delayed] = true

        define_method "grab_dimensions_for_#{name}" do
          if self.send("#{name}").dirty?
            # need to extract dimensions from the attachment
            self.attachment_for(name)._grab_dimensions
          end
        end

        define_method "enqueue_delayed_processing_for_#{name}" do 
          # we render on two things: image fingerprint changed, or image gravity changed
          if self.previous_changes.include?("image_fingerprint") || self.previous_changes.include?("image_gravity")
            ::Paperclip.log("[ewr] Reprocessing because of fingerprint or gravity change")
            self.attachment_for(name).enqueue
          end
        end

        # register our event handler
        before_save :"grab_dimensions_for_#{name}"
        
        if respond_to?(:after_commit)
          after_commit  :"enqueue_delayed_processing_for_#{name}"
        else
          after_save  :"enqueue_delayed_processing_for_#{name}"
        end
        

        ::Paperclip.interpolates"sprint" do |attachment,style_name|
          sprint = nil
          if style_name == :original
            sprint = 'original'
          else
            ao = attachment.instance.output_by_style(style_name)
            ::Paperclip.log("[EWR] in sprint interpolation for #{style_name}: #{ao} -- #{ao.fingerprint}")

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
        # borrowed from delayed_paperclip... combines with [:delayed] above to turn off the inline processing
        def attachment_for name
          @_paperclip_attachments ||= {}
          @_paperclip_attachments[name] ||= ::Paperclip::Attachment.new(name, self, self.class.attachment_definitions[name]).tap do |a|
            a.post_processing = false if self.class.attachment_definitions[name][:delayed]
          end
        end
      end      
    end
  end

  #----------

  class ResqueJob
    @queue = nil

    def self.perform(instance_klass, instance_id, attachment_name, *style_args)
      instance = instance_klass.constantize.find(instance_id)
      
      if style_args
        style_args.collect! { |s| s.to_sym }
      end
      
      instance.send(attachment_name).reprocess!(*style_args)
    end
  end

end

module Paperclip
  class Attachment

    # Overwrite styles loader to allow caching despite dynamic loading
    def styles
      styling_option = @options[:styles]
      
      if !@normalized_styles
        @normalized_styles = ActiveSupport::OrderedHash.new
        styling_option.call(self).each do |name, args|
          @normalized_styles[name] = Paperclip::Style.new(name, args.dup, self)
        end
      end
      @normalized_styles
    end

    #----------

    # overwrite to only delete original when clear() is called.  styles will 
    # be deleted by the thumbnailer
    def queue_existing_for_delete #:nodoc:
      return unless file?

      @queued_for_delete = [path(:original)]

      instance_write(:file_name, nil)
      instance_write(:content_type, nil)
      instance_write(:file_size, nil)
      instance_write(:updated_at, nil)
    end

    #----------
    
    def delete_style(style)
      if style.to_sym == :original
        # can't delete the original image through here
        return false
      end
      
      if self.exists?(style)
        @queued_for_delete = [ self.path(style) ]
        self.flush_deletes()
      end
    end
    
    #----------

    def delete_path(path)
      @queued_for_delete = [ path ]
      self.flush_deletes()
    end

    #----------

    def enqueue
      # queue up any outputs that a) already exist or b) are set to prerender
      styles = [
        AssetHostCore::Output.where(:prerender => true).collect(&:code_sym),
        self.instance.outputs.collect { |ao| ao.output.code_sym }
      ].flatten.uniq
      
      Resque.enqueue(AssetHostCore::ResqueJob,self.instance.class.name,self.instance.id,self.name,*styles)
    end

    def enqueue_styles(styles)
      Resque.enqueue(AssetHostCore::ResqueJob,self.instance.class.name,self.instance.id,self.name,styles)
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
            if g.square?
              # match w/h from style
              return g.width.to_i
            else
              return g.width.to_i
            end
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
            return g.height.to_i
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
        Rails.logger.debug "args is #{args}"
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

      Rails.logger.debug "style is #{s.instance_variable_get :@other_args}"

      if (s.instance_variable_get :@other_args)[:rich] && self.instance.native
        #return self.instance.native.tag(self.width(style),self.height(style))
        args = args.merge(self.instance.native.attrs())
      end

      htmlargs = args.collect { |k,v| %Q!#{k}="#{v}"! }.join(" ")

      return %Q(<img src="#{self.url(style)}" width="#{self.width(style)}" height="#{self.height(style)}" alt="#{self.instance.title}" #{htmlargs}/>).html_safe        
    end

    #----------

    def _grab_dimensions
      Paperclip.log("[ewr] grabbing dimensions for #{@queued_for_write[:original]}")

      return unless @queued_for_write[:original]

      begin
        p = ::MiniExiftool.new(@queued_for_write[:original].path)
      rescue
        Paperclip.log("[ewr] Failed to call MiniExifTool on #{@queued_for_write[:original].path}")
        return false
      end

      # -- determine metadata -- #

      title = ""
      description = ""
      copyright = ""

      if p.credit =~ /Getty Images/
        # smart import for Getty Images photos
        copyright = [p.by_line,p.credit].join("/")
        title = p.headline
        description = p.description
      elsif p.credit =~ /AP/
        # smart import for AP photos
        copyright = [p.by_line,p.credit].join("/")
        title = p.title
        description = p.description
      else
        copyright = p.byline || p.credit
        title = p.title
        description = p.description
      end

      instance_write(:width,p.image_width)
      instance_write(:height,p.image_height)
      instance_write(:title,title)
      instance_write(:description,description)
      instance_write(:copyright,copyright)
      instance_write(:taken,p.datetime_original)

      true
    end
  end
  
  #----------

  class AssetThumbnail < Paperclip::Thumbnail
    attr_accessor :prerender
    attr_accessor :output
    attr_accessor :asset

    def initialize file, options = {}, attachment = nil
      @prerender = options[:prerender]
      @size = options[:size]
      @output = options[:output]
      @asset = attachment ? attachment.instance : nil
      @attachment = attachment

      Paperclip.log("asset is #{@asset} -- output is #{@output}")

      super

      @convert_options = [ 
        "-gravity #{ @asset.image_gravity? ? @asset.image_gravity : "Center" }", "-strip", "-quality 80", @convert_options 
      ].flatten.compact

      Paperclip.log("[ewr] Convert options are #{@convert_options}")
    end

    # Perform processing, if prerender == true or we've had to render 
    # this output before. Afterward, update our  AssetOutput entry 
    def make
      # do we have an AssetOutput already?
      ao = @asset.outputs.where(:output_id => @output).first

      Paperclip.log("[ewr] make for #{@output} -- ao is #{ ao }")
      dst = nil

      if @prerender || ao
        if !ao 
          # register empty AssetObject to denote processing
          ao = @asset.outputs.create(:output_id => @output, :image_fingerprint => @asset.image_fingerprint)
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

        Paperclip.log("[ewr] Final convert_options are #{@convert_options}")

        # call thumbnail generator
        dst = super

        # need to get dimensions
        width = height = nil
        begin
          Paperclip.log("[ewr] Calling geo.from_file for #{dst.path}")
          geo = Geometry.from_file dst.path
          width = geo.width.to_i
          height = geo.height.to_i
          Paperclip.log("[ewr] geo run was successful -- #{width}x#{height}")
        rescue NotIdentifiedByImageMagickError => e
          # hmmm... do nothing?
        end

        # get fingerprint
        Paperclip.log("[ewr] dst path is #{dst.path}")
        print = Digest::MD5.hexdigest(dst.read)
        dst.rewind if dst.respond_to?(:rewind)

        Paperclip.log("[ewr] dst print is #{print}")

        ao.attributes = { :fingerprint => print, :width => width, :height => height, :image_fingerprint => @asset.image_fingerprint }
        ao.save

        # just to be safe...
        @asset.outputs(true)
      end

      return dst
    end
  end
end