module AssetHostCore::Loaders
  mattr_accessor :discovered
  @@discovered = []
    
  def self.load(url)
    asset = nil
    @@discovered.each { |iclass| 
      if loader = iclass.valid?(url)
        asset = loader.load()
        break
      end
    }
    
    return asset
  end
  
  def self.classes
    puts "Classes: " + @@discovered.to_s
  end
  
  class Base
    attr_accessor :title, :owner, :description, :url, :created, :file
    
    def self.inherited(subclass)
      # add to the loader list
      AssetHostCore::Loaders.discovered << subclass
      
      # make sure we stay sorted while loading
      AssetHostCore::Loaders.discovered.sort_by { |c| c.name.split("::")[-1] }
    end    
  end
end