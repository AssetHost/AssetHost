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
        
        @browser = $( @options['assetBrowserEl'] )
        @aloaderEl = $( @options['assetLoadingEl'] )
        @modal = $( @options['modal'] )
        
        if !@modal
            @modal = new Element('div',{id:@options['modal']})
            @browser.insert({before:@modal})
            
        #@modal.removeClassName('show')
                
        # load recent assets into asset browser
        @_loadingAssets = false
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
        jQuery.ajax("/api/assets",{
            parameters: { query: options['query'] || '', page: options['page'] || 1 },
            method: 'get',
            success: (data) =>
                ul = $("<ul/>")
                
                # for each asset, create an element on @browser
                for a in data.assets
                    el = $("<li/>",{id: a.id}).html(a.tags.thumb)
                    $(ul).append el

                    $(el).bind 'dragstart', a, (evt) ->
                        evt.originalEvent.dataTransfer.setData('text/uri-list',evt.data.url)
                        
                    #$(el).bind 'click', a, (evt) => @previewAsset(evt.data)

                @browser.html ul
                
                # add pagination links
                pagination = ''
                
                ###
                if h.pages.page > 1
                    prev = new Element('a',{class: "page_prev",href:""})
                    prev.insert("Previous Page")
                    prev.observe 'click', (evt) => 
                        @loadAssets { query: options['query'], page: h.pages.page - 1 }
                        evt.preventDefault()
                    @browser.insert { bottom: prev }
                    
                if h.pages.page < h.pages.pages
                    npage = new Element('a',{class: "page_next",href:""})
                    npage.insert("Next Page")
                    npage.observe 'click', (evt) => 
                        @loadAssets { query: options['query'], page: h.pages.page + 1 }
                        evt.preventDefault()
                    @browser.insert { bottom: npage }

                pinfo = new Element('p',{class: "page_info"})
                pinfo.insert("Page #{h.pages.page} of #{h.pages.pages}")
                @browser.insert { bottom: pinfo }
                ###
                    
                # turn off our load status
                @assetsLoading false
        })
        
        return false
        
    #----------
    
    assetsLoading: (bool) ->
        if bool then @aloaderEl.show() else @aloaderEl.hide()
    
    #----------
    
    previewAsset: (asset) ->            
        # create our elements
        div = new Element('div',{class:'ah_browse_asset'})
        div.insert({bottom:asset.tags.lead})
        div.insert({bottom:new Element('h1').update(asset.title)})
        div.insert({bottom:new Element('h2').update(asset.owner)})
        div.insert({bottom:new Element('h2').update(asset.size)})
        div.insert({bottom:new Element('p').update(asset.description)})
        
        use_link = new Element('a',{class:'awesome large'}).update("Use This Asset")
        use_link.observe()
        div.insert({bottom:use_link})
        
        @modal.update(div)
        @modal.addClassName("show")