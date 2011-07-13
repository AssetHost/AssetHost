class window.AssetHostBrowserUI
    DefaultOptions:
        {
            assetBrowserEl: "#asset_browser",
            assetLoadingEl: "#assets_loading",
            modal: "#asset_modal",
            server: "localhost:3000"
        }

    constructor: (options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
                
        @assets = new AssetHostModels.Assets
                
        @browser = $( @options['assetBrowserEl'] )
        @aloaderEl = $( @options['assetLoadingEl'] )
        @modal = $( @options['modal'] )
        
        @_loadingAssets = false
        
        if !@modal.length
            @modal = $ '<div/>', {id: @options['modal'].replace('#','')}
            $(@browser).before @modal
            
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
                
            $(el).bind 'click', a, (evt) => @previewAsset(evt.data)
        
        @browser.html ul
        
        @assetsLoading false
    
    #----------
    
    assetsLoading: (bool) ->
        if bool then @aloaderEl.show() else @aloaderEl.hide()
    
    #----------
    
    previewAsset: (asset) ->            
        # create our elements
        div = $('<div/>',{class:'ah_browse_asset'})
            .html(asset.get('tags').lead)
            .append($ '<h1/>', {text: asset.get('title')} )
            .append($ '<h2/>', {text: asset.get('owner')} )
            .append($ '<h2/>', {text: asset.get('size')} )
            .append($ '<p/>', {text: asset.get('description')} )
            .append($('<div/>', {text: "Close",href: ""}).bind("click",(el) => $(@modal).removeClass("show").hide(); false ))
        
        #use_link = new Element('a',{class:'awesome large'}).update("Use This Asset")
        #use_link.observe()
        #div.insert({bottom:use_link})
        
        $(@modal).html div        
        $(@modal).addClass("show").show()