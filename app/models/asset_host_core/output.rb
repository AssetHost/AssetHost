module AssetHostCore
  class Output < ActiveRecord::Base
    def code_sym
      self.code.to_sym
    end

    #----------

    def self.paperclip_sizes
      sizes = {}
      self.all.each do |o|
        sizes.merge! o.paperclip_options
      end

      return sizes
    end

    #----------

    def paperclip_options
      { self.code.to_sym => { :geometry => '', :size => self.size, :format => self.extension.to_sym, :prerender => self.prerender, :output => self.id, :rich => self.is_rich } }
    end
  end
end
