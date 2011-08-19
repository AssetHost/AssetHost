#= require assethost

class AssetHost.BrowserUI
    DefaultOptions:
        {
            assetBrowserEl: "#asset_browser",
            modalSelect: true
            modalAdmin: true            
        }
        
    constructor: (options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
                
        @assets = new AssetHost.Models.PaginatedAssets @options.assets||[]
        if @options.page
            @assets.page @options.page
        
        if @options.total
            @assets.total_entries = @options.total        
                        
        @browserEl = $( @options.assetBrowserEl )
        @browser = new AssetHost.Models.AssetBrowserView collection: @assets

        @browserEl.html @browser.el
        @browserEl.after @browser.pages().el
                
        # add search box
        @search = new AssetHost.Models.AssetSearchView collection:@assets
        $('#search_box').html @search.render().el
                
        # -- Handle Routing -- #
        
        @router = new @Router
        @router.bind "route:asset", (id) => @previewAsset id
        @router.bind "route:index", => @clearDisplay()
        @router.bind "route:search", (page,query) => 
            @clearDisplay()
            @loadAssets query:query, page:page
        
        # -- Handle Events from UI Elements -- #

        @browser.pages().bind "page", (page) => 
            @clearDisplay()
            @loadAssets page:page
            @navToAssets()
        
        @search.bind "search", (query) => 
            @clearDisplay()
            @loadAssets query:query, page:1
            @navToAssets()
            
        @browser.bind "click", (asset) =>
            console.log "clicked asset ", asset 
            @clearDisplay()
            @_previewAsset(asset)
            
        Backbone.history.start pushState:true, root:@options.root_path
        
        $(@browserEl).delegate "li", "dragstart", (evt) ->
            if url = $(evt.currentTarget).attr 'data-asset-url'
                evt.originalEvent.dataTransfer.setData 'text/uri-list', url
                                        
        @assets.trigger 'reset'
    
    #----------
        
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
    
    #----------
    
    # given a query string and/or page number, grab assets via the API and 
    # fill in the asset browser
    loadAssets: (options = {}) -> 
        qDirty = options['query'] && options['query'] != @assets.query()
        pDirty = options['page'] && Number(options['page']) != Number(@assets.page())
                        
        if qDirty || pDirty || options['force']
            # display loading status. browserView will clear on its own
            @browser.loading()
        
            # fire off AJAX API request
            @assets.query(options['query'])
            @assets.page(options['page'])
            @assets.fetch()
        
            return false
                
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
            a = new AssetHost.Models.Asset({id:id})
            a.fetch({success:(a)=>@_previewAsset(a)})
        else 
            @_previewAsset(asset)
        
    _previewAsset: (asset) ->
        asset.modal().open 
            options:
                close:  => @navToAssets(),
            select: @options.modalSelect,
            admin:  @options.modalAdmin
    
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