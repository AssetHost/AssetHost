class window.AssetHostChooserUI
    DefaultOptions:
        {
            dropEl: "my_assets",
            assetBrowserEl: "asset_browser",
            assetLoadingEl: "assets_loading",
            server: "localhost:3000"
        }

    constructor: (options) ->
        @options = Object.extend(Object.extend({},this.DefaultOptions), options || {})
        
        @drop = $( @options['dropEl'] )
        @browser = $( @options['assetBrowserEl'] )
        @aloaderEl = $( @options['assetLoadingEl'] )
        
        # attach drag-n-drop listeners to my_assets
        @drop.observe "dragenter", (evt) => @_dropDragEnter evt
        @drop.observe "dragover", (evt) => @_dropDragOver evt
        @drop.observe "drop", (evt) => @_dropDrop evt
        
        @_loadingAssets = false
        
        # load recent assets into asset browser
        @loadAssets { query: '', page: 1 }
    
    #----------
        
    # given a query string and/or page number, grab assets via the API and 
    # fill in the asset browser
    loadAssets: (options = {}) -> 
        # display loading status
        @assetsLoading true
        
        # fire off AJAX API request
        new Ajax.Request("/api/assets",{
            parameters: { query: options['query'] || '', page: options['page'] || 1 },
            method: 'get',
            onSuccess: (resp) =>
                ul = new Element('ul')
                
                h = resp.responseJSON
                
                # for each asset, create an element on @browser
                for a in h.assets
                    el = new Element('li',{id: a.id})
                    el.update(a.tags.thumb)
                    ul.insert {bottom:el}
                    el.observe 'dragstart', (evt) => evt.dataTransfer.setData('text/uri-list',a.url) 
            
                @browser.update(ul)
                
                # add pagination links
                pagination = ''
                
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
                
                    
                # turn off our load status
                @assetsLoading false
        })
        
        return false
        
    #----------
    
    assetsLoading: (bool) ->
        if bool then @aloaderEl.show() else @aloaderEl.hide()
    
    #----------

    _dropDragEnter: (evt) ->
        console.log "In _dragEnter", evt
        
        uri = evt.dataTransfer.getData('text/uri-list')
        
        console.log "uri-list is ", uri
        
        
        evt.stopPropagation()
        evt.preventDefault()
        false
    
    _dropDragOver: (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        false
        
    #----------
    
    # When we receive a drop, we need to test whether it is an asset (or can
    # be made into an asset), and if so add it to our display.  
    _dropDrop: (evt) ->
        console.log "drop evt: ", evt 
        
        uri = evt.dataTransfer.getData('text/uri-list')
        
        console.log "uri-list is ", uri
        
        #new Ajax.Request("/api/as_asset",{
        #    parameters: { url: uri},
        #    onSuccess: (resp) => @_handleResponse resp
        #})
		
        evt.stopPropagation()
        evt.preventDefault()
        false
    
    _handleResponse: (resp) ->
        console.log 'resp is ', resp
        
        if resp
            @callback resp.responseJSON