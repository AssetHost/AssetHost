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
      sizes[ o.code.to_sym ] = [o.size,o.extension.to_sym]
    end
    
    return sizes
  end

end
