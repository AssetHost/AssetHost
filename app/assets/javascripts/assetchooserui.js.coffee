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
        
        @drop = $( @options['dropEl'] )
        
        @myassets = []
        @myassetsEl = $("<ul/>",{class:"my_assets"})
            
        @uploads = []
        @uploadsEl = $("<ul/>",{class:"my_uploads"})

        @drop.append(@myassetsEl,@uploadsEl)
            
        # do we have an asset browser to attach to?
        @browser = this.options.browser || false 
            
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
                        @addMyAsset data
                    else
                        # No...  Display error
                        alert data.error
            })
		
        evt.stopPropagation()
        evt.preventDefault()
        false
        
    #----------
    
    addMyAsset: (asset) ->
        console.log "adding asset #{asset.id}"
        
        # -- create asset thumbnail element -- #
        
        # <li><img/> 
        #   <b>ID: TITLE</b>
        #   <p>CAPTION [edit]</p>
        # </li>
        
        caption = @chopCaption(asset.description)
        
        li = $("<li/>",{id:"mya_#{asset.id}"})
            .append(
                asset.tags.thumb,
                $("<b/>").text("#{asset.id}: #{asset.title}"),
                $("<p/>").text(caption)
            )
        
        asset.li = li

        @myassets.push asset
        @myassetsEl.append li
        
        # -- make the asset thumbnail list sortable -- #
        
        # -- add a link to edit caption interface -- #
        
        
        
        asset
    
    #----------
        
    chopCaption: (caption,count=100) ->
        chopped = caption
        
        if caption and caption.length > count
            regstr = "^(.{#{count}}\\w*)\\W"
            chopped = caption.match(new RegExp(regstr))
            
            if chopped
                chopped = "#{chopped[1]}..."
            else
                chopped = caption
                
        chopped