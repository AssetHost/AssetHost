module AssetHostCore::Natives
  mattr_accessor :discovered
  @@discovered = []
  
  def self.classes
    puts "Classes: " + @@discovered.to_s
  end
  
  def self.natives
    @@discovered
  end
  
  class Base
    cattr_accessor :model
    cattr_accessor :display_name
    
    
    def self.inherited(subclass)
      # add to the loader list
      AssetHostCore::Natives.discovered << subclass
      
      # make sure we stay sorted while loading
      AssetHostCore::Natives.discovered.sort_by { |c| c.name.split("::")[-1] }
    end    
    
  end
end