#= require assethost
#= require jquery.livequery
#= require underscore
#= require slideshow

#= require_self
#= require_tree ./clients

class AssetHost.Client
    DefaultOptions:
        attr: "data-assethost"
    
    constructor: (options) ->
        @options = _(_({}).extend(@DefaultOptions)).extend options||{}
        
        @clients = []
        
        clients = @clients

        $ =>
            ahAttr = @options.attr
            
            # find all assethost elements and look for rich functionality
            $("img[#{@options.attr}]").livequery ->
                rich = $(this).attr ahAttr
                
                if Client[rich]
                    clients.push new Client[rich](this)
                    
    #----------
