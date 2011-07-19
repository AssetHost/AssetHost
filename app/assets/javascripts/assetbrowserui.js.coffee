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
                
        @browserEl = $( @options['assetBrowserEl'] )
        @browser = new AssetHostModels.AssetBrowserView({collection: @assets})

        @browserEl.after( @browser.pages().el )
        
        @aloaderEl = $( @options['assetLoadingEl'] )
        @modal = $( @options['modal'] )
        
        # add search box
        @search = new AssetHostModels.AssetSearchView({collection:@assets})
        $('#search_box').html @search.render().el
        
        @_loadingAssets = false
        
        # -- Handle Routing -- #
        
        @router = new @Router
        @router.bind("route:asset",(id) => @previewAsset id )
        @router.bind("route:index", => @clearDisplay() )
        @router.bind("route:search", (page,query=null) => 
            @clearDisplay()
            @loadAssets { query: query, page: page }
        )
        
        # -- Handle Events from UI Elements -- #

        @browser.pages().bind("page", (page) => 
            @clearDisplay()
            @loadAssets { page: page }
            @navToAssets()
        )
        
        @search.bind "search", (query) => 
            @clearDisplay()
            @loadAssets { query: query, page: 1 }
            @navToAssets()
            
        Backbone.history.start()
        
        $(@browserEl).delegate "li", "dragstart", (evt) ->
            if (url = $(evt.currentTarget).attr('data-asset-url'))
                evt.originalEvent.dataTransfer.setData('text/uri-list',url)
                                    
        @assets.bind 'reset', (assets) => 
            @browserEl.html @browser.render().el
            @assetsLoading false
                
        # load recent assets into asset browser
        if !@_assetsLoading
            @loadAssets { query: '', page: 1, force: true }
    
    #---------------------#
    # -- Asset Browser -- #
    #---------------------#
        
    navToAssets: ->
        page = @assets.page()
        query = @assets.query()
        
        console.log "navToAssets page/query are ",page,query
        
        if page && query
            @router.navigate("/p/#{page}/#{query}")
        else if page && page != 1
            @router.navigate("/p/#{page}")
        else
            @router.navigate("/")
    
    # given a query string and/or page number, grab assets via the API and 
    # fill in the asset browser
    loadAssets: (options = {}) -> 
        qDirty = options['query'] && options['query'] != @assets.query()
        pDirty = options['page'] && Number(options['page']) != Number(@assets.page())
                        
        if qDirty || pDirty || options['force']
            # display loading status
            @assetsLoading true
        
            # fire off AJAX API request
            @assets.query(options['query'])
            @assets.page(options['page'])
            @assets.fetch()
        
            return false
        
    #----------
        
    assetsLoading: (bool) ->
        if bool
            @aloaderEl.show()
            @_assetsLoading = true
        else 
            @aloaderEl.hide()
            @_assetsLoading = false
    
    #----------
    
    clearDisplay: ->
        console.log "in clearDisplay"
        # clear any asset modal
        $(".ui-dialog-titlebar-close").trigger('click')
    
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
        asset.modal().open({close: => @navToAssets()})
    
    #----------    
    
    Router:
        Backbone.Router.extend({
            routes:
                {
                    '/a/:id': "asset",
                    '/p/:p/:query': "search",
                    '/p/:p': "search",
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