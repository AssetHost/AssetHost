module AssetHost::Loaders
  class Asset < AssetHost::Loaders::Base    
    attr_reader :source, :id
    
    def self.valid?(url)
      if url =~ /#{ASSET_SERVER}\/api\/assets\/(\d+)\/?/
        return self.new($~[1])
      elsif url =~ /#{ASSET_SERVER}\/i\/[^\/]+\/(\d+)-/
        return self.new($~[1])
      else  
        return nil
      end
    end
    
    def initialize(id)
      @source = "Asset"
      @id = id
    end
    
    def load
      a = ::Asset.find(@id)
      return a
    rescue
      return nil
    end
  end
end