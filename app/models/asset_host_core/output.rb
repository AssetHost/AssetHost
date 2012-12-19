module AssetHostCore
  class Output < ActiveRecord::Base
    has_many :asset_outputs
    
    after_save :delete_asset_outputs, :if => Proc.new { |o| o.size_changed? || o.extension_changed? }
    
    attr_accessible :code, :size, :extension, :prerender, :is_rich
    
    #----------
    
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
    
    #----------
    
    protected
    
    def delete_asset_outputs
      # destroy each AssetOutput, triggering file and cache deletion
      self.asset_outputs.each { |ao| ao.destroy() }
    end
  end
end
