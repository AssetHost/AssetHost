class window.AssetHostChooserUI
    DefaultOptions:
        {
            dropEl: "#my_assets",
            server: "<%= ASSET_SERVER %>",
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
                    
        @uploads = new AssetHostChooserUI.QueuedFiles
        @uploads.bind "uploaded", (f) =>
            @myassets.add(f.get('ASSET'))
            @uploads.remove(f)
        
        @uploadsView = new AssetHostChooserUI.QueuedFilesView({collection:@uploads})
        
        @saveAndClose = new AssetHostModels.SaveAndCloseView({collection: @myassets}).render()
        
        @saveAndClose.bind('saveAndClose', (json) => console.log "saving and closing ",json;@trigger('saveAndClose',json))

        @drop.append(@assetsView.el,@uploadsView.el)
        @drop.after(@saveAndClose.el)
            
        # attach drag-n-drop listeners to my_assets
        @drop.bind "dragenter", (evt) => @_dropDragEnter evt
        @drop.bind "dragover", (evt) => @_dropDragOver evt
        @drop.bind "drop", (evt) => @_dropDrop evt
        
    #----------
    
    selectAssets: (assets) ->
        for obj in assets
            asset = @myassets.get(obj.id)

            if !asset
                asset = new AssetHostModels.Asset({id:obj.id,description:obj.description})
                asset.fetch({success:(a)=>a.set({description:obj.description});@myassets.add(a)})
    
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
                
        if evt.dataTransfer.files.length > 0
            # drop is file(s)... stage for uploader

            console.log("We got files!")            
            for f in evt.dataTransfer.files
                @uploads.add({ name: f.name, size: f.size, file: f })

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
    
    @queuedSync: (method,model,success,error) ->
        console.log "in sync"
                
    @QueuedFile:
        Backbone.Model.extend({
            sync: @queuedSync
            urlRoot: '/a/assets/upload'
            
            upload: ->
                return false if @xhr
                
                @xhr = new XMLHttpRequest
                
                $(@xhr.upload).bind "progress", (evt) => 
                    evt = evt.originalEvent
                    @set {"PERCENT": if evt.lengthComputable then Math.floor(evt.loaded/evt.total*100) else evt.loaded}
                    
                $(@xhr.upload).bind "complete", (evt) =>
                    @set {"STATUS": "pending"} 
                
                @xhr.onreadystatechange = (req) => 
                    console.log "in onreadystatechange",req
                    if @xhr.readyState == 4 && @xhr.status == 200
                        console.log "got complete status"
                        @set {"STATUS": "complete"}
                        
                        if req.responseText != "ERROR"
                            @set {"ASSET": $.parseJSON(@xhr.responseText)}
                            @trigger "uploaded", this
                
                @xhr.open('POST',this.urlRoot, true);
                @xhr.setRequestHeader('X_FILE_NAME', @get('file').fileName)
                @xhr.setRequestHeader('CONTENT_TYPE', @get('file').type)
                @xhr.setRequestHeader('HTTP_X_FILE_UPLOAD','true')
                    
                # and away we go...
                @xhr.send @get('file')                
                @set {"STATUS": "uploading"}
            
            readableSize: ->
                return false if !@get('size')
                size = @get('size')
                
                units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
                i = 0;

                while size >= 1024
                    size /= 1024
                    ++i

                size.toFixed(1) + ' ' + units[i];
                
            
        })
    
    #----------
        
    @QueuedFiles: 
        Backbone.Collection.extend({
            model: @QueuedFile


        })
        
    #----------
    
    @QueuedFileView:
        Backbone.View.extend({
            events:
                {
                    'click button.remove': '_remove',
                    'click button.upload': '_upload'
                }
            
            tagName: "li"
            template:
                '''
                <%= name %>: <%= size %> 
                <% if (STATUS == 'uploading') { %>
                    (<%= PERCENT %>%)
                <% }; %>
                <button class="remove small awesome red">x</button>
                <button class="upload small awesome green">Upload</button>
                '''
            
            initialize: ->
                @render()
                @model.bind "change", => @render()
                
            _remove: (evt) ->
                console.log "calling remove for ",this
                @model.collection.remove(@model)    
                
            _upload: (evt) ->
                @model.upload()
            
            render: ->
                $( @el ).attr('class',@model.get("STATUS"))
                
                $( @el ).html( _.template(@template,{
                    name: @model.get('name'),
                    size: @model.readableSize(),
                    STATUS: @model.get('STATUS'),
                    PERCENT: @model.get('PERCENT')
                }))

                return this
        })
        
    #----------
        
    @QueuedFilesView:
        Backbone.View.extend({ 
            tagName: "ul"
            className: "uploads"
            
            initialize: ->
                @_views = {}
                
                @collection.bind 'add', (f) => 
                    console.log "add event from ", f
                    @_views[f.cid] = new AssetHostChooserUI.QueuedFileView({model:f})
                    @render()
                    
                @collection.bind 'remove', (f) => 
                    console.log "remove event from ", f
                    $(@_views[f.cid].el).detach()
                    delete @_views[f.cid]
                    @render()

                @collection.bind 'reset', (f) => 
                    console.log "reset event from ", f
                    @_views = {}
                                        
                console.log "collection is ", @collection
                
            _reset: (f) ->
                console.log "reset event from ",f
                       
            render: ->
                # set up views for each collection member
                @collection.each (f) => 
                    # create a view unless one exists
                    @_views[f.cid] ?= new AssetHostChooserUI.QueuedFileView({model:f})
                
                # make sure all of our view elements are added
                $(@el).append( _(@_views).map (v) -> v.el )
                console.log "rendered files el is ",@el
                
                return this
        })