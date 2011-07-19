class window.AssetHostChooserUI
    DefaultOptions:
        {
            dropEl: "#my_assets",
            server: "localhost:3000",
            modal: "asset_modal",
            browser: ''
        }

    #----------

    constructor: (options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
        
        # add in events
        _.extend(this, Backbone.Events)
        
        # do we have an asset browser to attach to?
        @browser = this.options.browser || false 
        
        @drop = $( @options['dropEl'] )
        
        @myassets = new AssetHostModels.Assets
        @assetsView = new AssetHostModels.AssetDropView({collection: @myassets})
        
        @assetsView.bind 'click', (asset) =>  
            asset.editModal().open()
        
        @assetsView.bind 'remove', (asset) => 
            if confirm("Remove?")
                @myassets.remove(asset)
                
        @browser.assets.bind "selected", (asset) => 
            console.log "got selected from ", asset
            @myassets.add(asset)
            asset.editModal().open()
                    
        @uploads = []
        @uploadsEl = $("<ul/>",{class:"my_uploads"})

        @saveAndClose = new AssetHostModels.SaveAndCloseView({collection: @myassets}).render()
        
        @saveAndClose.bind('saveAndClose', (json) => console.log "saving and closing ",json;@trigger('saveAndClose',json))

        @drop.append(@assetsView.el,@uploadsEl)
        @drop.after(@saveAndClose.el)
            
        # attach drag-n-drop listeners to my_assets
        @drop.bind "dragenter", (evt) => @_dropDragEnter evt
        @drop.bind "dragover", (evt) => @_dropDragOver evt
        @drop.bind "drop", (evt) => @_dropDrop evt
    
    #----------
    
    _dropDragEnter: (evt) ->
        evt = evt.originalEvent
        evt.stopPropagation()
        evt.preventDefault()
        false
    
    _dropDragOver: (evt) ->        
        evt = evt.originalEvent
        evt.stopPropagation()
        evt.preventDefault()
        false
        
    #----------
    
    # When we receive a drop, we need to test whether it is an asset (or can
    # be made into an asset), and if so add it to our display.  
    _dropDrop: (evt) ->
        evt = evt.originalEvent
        
        console.log "drop evt: ", evt 
        
        if evt.dataTransfer.files.length > 0
            # drop is file(s)... stage for uploader
            
            console.log("We got files!")
        else
            # drop is a URL. Pass it to AssetHost API and see what happens
            
            uri = evt.dataTransfer.getData('text/uri-list')        
            console.log "uri-list is ", uri
            
            jQuery.ajax("/api/as_asset",{
                data: { url: uri},
                success: (data) => 
                    # did we get an Asset in response?
                    if data.id
                        # Yes...  Add as asset
                        @myassets.add(data)
                    else
                        # No...  Display error
                        alert data.error
            })
		
        evt.stopPropagation()
        evt.preventDefault()
        false
    
    #----------