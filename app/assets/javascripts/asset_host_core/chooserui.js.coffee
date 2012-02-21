#= require ./assethost

#= require ./templates/edit_modal

class AssetHost.ChooserUI
    DefaultOptions:
        dropEl: "#my_assets"
        browser: ''
        saveButton: 1
        assets: true
        uploads: true
        limit: 0
        uploadPath: '/a/assets/upload'

    #----------

    constructor: (options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
        
        # add in events
        _.extend(this, Backbone.Events)
        
        # do we have an asset browser to attach to?
        @browser = this.options.browser || false 
        
        @drop = $( @options['dropEl'] )
        
        # hang onto whatever starts out in drop... we'll use it when it's empty
        @emptyMsg = $ '<div/>', html: @drop.html()
        @drop.html @emptyMsg
        
        # set up collection and view to manage assets
        @myassets = new AssetHost.Models.Assets
        @assetsView = new AssetHost.Models.AssetDropView collection: @myassets
        
        @assetsView.bind 'click', (asset) =>
            new ChooserUI.EditModal model:asset
        
        @assetsView.bind 'remove', (asset) => 
            @myassets.remove(asset)
                
        # connect to our AssetBrowser instance, if one is given        
        if @browser
            @browser.assets.bind "selected", (asset) => 
                console.log "got selected from ", asset
                @myassets.add(asset)
                new ChooserUI.EditModal model:asset
                
            @browser.assets.bind "admin", (asset) => 
                console.log "got admin event from ", asset
                window.open("/a/assets/#{asset.get('id')}")
                    
        # set up collection to manage uploads and convert to assets
        @uploads = new AssetHost.Models.QueuedFiles null, urlRoot:@options.uploadPath
        @uploads.bind "uploaded", (f) =>
            @myassets.add(f.get('ASSET'))
            @uploads.remove(f)

        @uploadsView = new AssetHost.Models.QueuedFilesView collection:@uploads
        
        # manage the msg that shows when we have no assets or uploads
        @myassets.bind "all", () => @_manageEmptyMsg()
        @uploads.bind "all", () => @_manageEmptyMsg()
        
        # manage the upload all button
        @uploadAll = new ChooserUI.UploadAllButton collection:@uploads
        @drop.after @uploadAll.el
        
        # manage button that pops up after uploads
        if @options.afterUploadURL and @options.afterUploadText
            @afterUpload = new ChooserUI.AfterUploadButton 
                collection:@uploads, 
                text:@options.afterUploadText, 
                url:@options.afterUploadURL
                
            @drop.after @afterUpload.el
        
        # add our two lists into the drop zone
        @drop.append(@assetsView.el,@uploadsView.el)
        
        # should we add a Save and Close button to the display?
        if @options.saveButton
            @saveAndClose = new AssetHost.Models.SaveAndCloseView collection: @myassets
            @saveAndClose.bind 'saveAndClose', (json) => @trigger 'saveAndClose', json
            @drop.after @saveAndClose.el
            
        # attach drag-n-drop listeners to my_assets
        @drop.bind "dragenter", (evt) => @_dropDragEnter evt
        @drop.bind "dragover", (evt) => @_dropDragOver evt
        @drop.bind "drop", (evt) => @_dropDrop evt
            
    #----------
    
    _manageEmptyMsg: ->
        if @myassets.length + @uploads.length > 0
            # turn empty msg off
            $(@emptyMsg).slideUp()
        else
            # turn empty msg on
            $(@emptyMsg).slideDown()
    
    #----------
    
    selectAssets: (assets) ->
        _(assets).each (obj) => 
            asset = @myassets.get(obj.id)

            if !asset
                asset = new AssetHost.Models.Asset(obj)
                asset.fetch success:(a)=>
                    a.set caption:obj.caption
                    
                    if obj.ORDER
                        a.set ORDER:obj.ORDER 
                        
                    @myassets.add(a)
                    
        @myassets.sort()
    
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
        
        evt.stopPropagation()
        evt.preventDefault()
        
        # first thing we need to test is whether we have a limit on uploads
        if @options.limit && @uploads.length >= @options.limit
            # we're at our limit...  shake our UI element and then do nothing
            console.log "upload attempted above limit..."
            $(@drop).effect "shake", {times: 3}, 100
            return false
            
        # if we get here, we're allowed to take an upload
        if evt.dataTransfer.files.length > 0
            # drop is file(s)... stage for uploader
            console.log "We got files!"            
            for f in evt.dataTransfer.files
                @uploads.add name: f.name, size: f.size, file: f

        else
            # drop is a URL. Pass it to AssetHost API and see what happens
            uri = evt.dataTransfer.getData 'text/uri-list'
            console.log "uri-list is ", uri
            
            jQuery.ajax "/api/as_asset",
                data: { url: uri},
                success: (data) => 
                    # did we get an Asset in response?
                    if data.id
                        # Yes...  Add as asset
                        @myassets.add data
                    else
                        # No...  Display error
                        alert data.error
		
        false
    
    #----------
    
    @EditModal:
        Backbone.View.extend
            className: "ah_asset_edit modal"
                
            events:
                'click button.save': '_save'
                'click button.admin': '_admin'
            
            #----------
            
            initialize: (options) ->
                # stash model attributes for later comparison
                @original = 
                    title: @model.get("title")
                    owner: @model.get("owner")
                    notes: @model.get("notes")
                    
                $(@render().el).modal()
                                
                # bind model to form
                Backbone.ModelBinding.bind(this)
                
                # attach listener for metadata changes
                @model.bind "change", =>                    
                    if _(@original).any((v,k) => v != @model.get(k))
                        @meta_dirty = true
                        @$(".meta_dirty").show()
                    else 
                        @meta_dirty = false
                        @$(".meta_dirty").hide()
                
            #----------
                
            close: ->
                Backbone.ModelBinding.unbind(this)
                $(@el).modal('hide')
            
            #----------
            
            _save: -> 
                # see whether we should save anything back to the server
                if @meta_dirty || @$("#save_caption_check")[0].checked
                    @model.clone().fetch success:(m)=>
                        # set title,owner,notes
                        attr = title:@model.get("title"),owner:@model.get("owner"),notes:@model.get("notes")                        
                    
                        if @$("#save_caption_check")[0].checked
                            attr.caption = @model.get("caption")
                        
                        m.save(attr)
                        @close()
                        
                else
                    @close()
            
            #----------
            
            _admin: -> 
                window.open("/a/assets/#{@model.get('id')}") 
            
            #----------    
            
            render: ->
                $(@el).html JST["asset_host_core/templates/edit_modal"] @model.toJSON()
                
                # set metadata state
                @$(".meta_dirty").hide()
                
                # set default state for caption save checkbox
                if @model.get("caption") && @model.get("caption") != ''
                    # leave it unchecked
                else
                    @$("#save_caption_check")[0].checked = true
                
                @
    
    #----------
    
    @AfterUploadButton:
        Backbone.View.extend
            template:
                """
                <button id="afterUpload" class="btn btn-large btn-success">
                    <%= text %>
                </button>
                """
                
            events:
                'click button': '_clicked'
                
            initialize: (options) ->
                @text = options.text
                @url = options.url
                
                @ids = []

                @collection.bind "uploaded", (f) => 
                    @ids.push f.get('ASSET').id
                    @render()                
                                
            _clicked: ->
                window.location = _.template @url.replace(/{{([^}]+)}}/,"<%= $1 %>"), ids:@ids.join(",") 
                
            render: ->
                if @ids
                    $(@el).html _.template @template, {text: @text}
    
    #----------
    
    @UploadAllButton:
        Backbone.View.extend({
            template:
                """
                <button id="uploadAll" class="btn btn-large btn-warning">
                    Upload All
                    <% if (count) { %>(<%= count %> Images)<% } %>
                </button>
                """
                
            events: { 'click button': 'uploadAll' }
                
            initialize: ->
                @collection.bind "all", => @render()

            uploadAll: -> 
                @collection.each (f) -> 
                    if !f.xhr
                        f.upload()
                                
            render: ->
                staged = @collection.reduce( 
                    (i,f) -> if f.xhr then i else i+1
                , 0)
                
                $( @el ).html if staged > 1 then _.template(@template,{count:staged}) else ''
                    
                return @
        })