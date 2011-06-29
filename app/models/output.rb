class Output < ActiveRecord::Base
  belongs_to :site_package
  
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
    { self.code.to_sym => { :geometry => self.size, :format => self.extension.to_sym, :prerender => self.prerender, :output => self.id } }
  end

end
