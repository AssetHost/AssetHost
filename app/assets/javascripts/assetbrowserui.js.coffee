class window.AssetHostBrowserUI
    DefaultOptions:
        {
            assetBrowserEl: "#asset_browser",
            assetLoadingEl: "#assets_loading",
            server: "localhost:3000"
        }
        
    constructor: (options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
                
        @assets = new AssetHostModels.Assets
                
        @browser = $( @options['assetBrowserEl'] )
        @aloaderEl = $( @options['assetLoadingEl'] )
        @modal = $( @options['modal'] )
        
        @_loadingAssets = false
        
        @router = new @Router
        @router.bind("route:asset",(id) => @previewAsset id )
        @router.bind("route:index", => @clearDisplay() )
        Backbone.history.start()
                    
        @assets.bind 'reset', (assets) => @_renderAssets(assets)
                
        # load recent assets into asset browser
        @loadAssets { query: '', page: 1 }
    
    #---------------------#
    # -- Asset Browser -- #
    #---------------------#
        
    # given a query string and/or page number, grab assets via the API and 
    # fill in the asset browser
    loadAssets: (options = {}) -> 
        # display loading status
        @assetsLoading true
        
        # fire off AJAX API request
        @assets.fetch({
            parameters: { q: options['query'] }
        })
        
        return false
        
    #----------
    
    _renderAssets: (assets) ->
        ul = $("<ul/>")
                
        assets.each (a) =>
            el = $("<li/>",{id: a.get('id')}).html(a.get('tags').thumb)
            $(ul).append el

            $(el).bind 'dragstart', a, (evt) ->
                evt.originalEvent.dataTransfer.setData('text/uri-list',evt.data.get('url'))
                
            $(el).bind 'click', a, (evt) => @router.navigate("#/a/"+evt.data.get('id'),true)
        
        @browser.html ul
        
        @assetsLoading false
    
    #----------
    
    assetsLoading: (bool) ->
        if bool then @aloaderEl.show() else @aloaderEl.hide()
    
    #----------
    
    clearDisplay: ->
        console.log "in clearDisplay"
        # clear any asset modal
        $.modal.close()
    
    #----------
    
    previewAsset: (id) ->
        console.log "in previewAsset for ",id
        
        # check if we have the asset
        asset = @assets.get(id) 

        if !asset
            a = new AssetHostModels.Asset({id:id})
            a.fetch({success:(a)=>@_previewAsset(a)})
        else 
            @_previewAsset(asset)
        
    _previewAsset: (asset) ->
        console.log "_previewAsset for ",asset.toJSON()
        $(asset.modal().render().el).modal({
            overlayClose: true,
            onClose: (modal) => @router.navigate("/");$.modal.close()
        })
    
    #----------    
    
    Router:
        Backbone.Router.extend({
            routes:
                {
                    '/a/:id': "asset",
                    '/s/:query': "search",
                    '/s/:query/:p': "search",
                    '/': "index",
                    '': "index"
                    
                }
                
            asset: ->
                console.log "in asset function"
                
            search: -> 
                console.log "in search function"
                
            index: ->
                console.log "in index function"
                
                
        })