class AssetHost.CMSPlugin
    DefaultOptions:
        {
            el: "",
            server: '',
            assets: [],
            token: ''
        }

    #----------

    constructor: (options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
        
        # add in events
        _.extend(this, Backbone.Events)
        
        # cache values for extras
        _(@options.extras).each (v,k) =>
            if v and el = $( '#'+v )[0]
                @options.extras[k] = el.value
        
        # store existing form row info
        @rows = []
        
        # -- assemble our asset list from form data -- #
        assetdata = []
        for idx in _.range(@options.begins_with,100)
            if el = $( _.template("#"+@options.assetID,{idx:idx,field:@options.id}) )[0]                
                asset = {
                    id: el.value,
                    caption: $( _.template("#"+@options.assetID,{idx:idx,field:@options.caption}) )[0].value,
                    #ORDER: $(_.template("#"+@options.assetID,{idx:idx,field:@options.order}) )[0].value
                    ORDER: idx
                }
                
                console.log "original caption is ", asset.caption
                
                # stash row info
                @rows.push {
                    idx: idx,
                    id: asset.id,
                    extras: _(@options.extras).map (v,field) => 
                        el = $( _.template("#"+@options.assetID,{idx:idx,field:field}) )[0]
                        { id: el.id, name: el.name, value: el.value }
                }
                
                assetdata.push(asset)
            else
                # nothing with this index, so go ahead and break
                break
                
        console.log "Parsed asset data is ", assetdata
        
        # -- load assets -- #
        
        @assets = new AssetHost.Models.Assets(assetdata)

        # load other asset data (tags, credit, etc)
        @assets.each (a,idx) -> a.fetch({success: (a) => a.set({caption:assetdata[ idx ].caption});console.log("set caption to ",assetdata[ idx ].caption)})
        
        # -- clone any hidden inputs -- #
        
        @hiddens = $(@options.el).find("input[type=hidden]")
        
        # -- initialize our views -- #
        
        @assetsView = new AssetHost.CMSPlugin.CMSAssets({collection:@assets,args:@options,rows:@rows,hiddens:@hiddens})
        $(@options.el).html @assetsView.el
        
        window.addEventListener "message", (evt) => 
            if evt.data != "LOADED"
                console.log "got reply of ", evt
                
                found = {}
                
                # reconsile our asset list to the returned list
                _(evt.data).each (a,i) =>
                    # do we have this asset?
                    if asset = @assets.get(a.id)
                        # yes... check for changed caption
                        asset.set({caption:a.caption,ORDER:i})
                    else
                        # no, needs to be added
                        asset = new AssetHost.Models.Asset(a)
                        asset.fetch(success: (aobj)=>aobj.set({caption:a.caption,ORDER:i});@assets.add(aobj))
                    
                    found[ a.id ] = true
                
                # now check for removed assets
                remove = []
                @assets.each (a,i) => 
                    if found[a.get('id')]
                        # we're cool
                        console.log "found asset: ", a.get('id')
                    else
                        # not in our return list... delete
                        console.log "removing asset: ", a.get('id')
                        remove.push(a)
                        
                for a in remove
                    @assets.remove(a)
                    
                @assets.sort()
                @assetsView.render()
                    
                @trigger("assets",@assets.toJSON())
        , false
    
    #----------
    
    @CMSAsset: Backbone.View.extend
        tagName: "li"
        
        template:
            '''
            <%= asset.tags ? asset.tags.thumb : "INVALID" %>
            <b><%= asset.title %> (<%= asset.size %>)</b>
            <p><%= asset.caption %></p>
            <input type="hidden" id="<%= id.id %>" name="<%= id.name %>" value="<%= asset.id %>" />
            <input type="hidden" id="<%= caption.id %>" name="<%= caption.name %>" value="<%= (asset.caption||"").replace(/"/g,'&quot;') %>" />
            <input type="hidden" id="<%= order.id %>" name="<%= order.name %>" value="<%= idx+1 %>" />
            <% _(extras).each(function(ex) { %>
                <input type="hidden" id="<%= ex.id %>" name="<%= ex.name %>" value="<%= ex.value %>" />
            <% }); %>
            '''
        
        initialize: ->
            # if we get an invalid asset, remove it
            if !@model.get("id")
                @model.collection.remove(@model)
                return false
            
            $(@el).attr("data-asset-url",@model.get('url'))
            @render()
            @model.bind "change", => @render()

        render: ->
            
            if @model.get('tags')            
                idx = @model.get('ORDER')
                #idx = @model.collection.indexOf(@model)
                                    
                if @options.rows[idx]
                    extras = @options.rows[idx].extras
                else
                    extras = _(@options.args.extras).map (v,k) => {
                        id: _.template(@options.args.assetID,{idx:idx,field:k}),
                        name: _.template(@options.args.assetName,{idx:idx,field:k}),
                        value: v
                    }
                                                                            
                $( @el ).html( _.template @template, {
                   asset: @model.toJSON(),
                   idx: idx,
                   id: {
                       id: _.template(@options.args.assetID,{idx:idx,field:@options.args.id}),
                       name: _.template(@options.args.assetName,{idx:idx,field:@options.args.id})
                   },
                   caption: {
                       id: _.template(@options.args.assetID,{idx:idx,field:@options.args.caption}),
                       name: _.template(@options.args.assetName,{idx:idx,field:@options.args.caption})
                   },
                   order: {
                       id: _.template(@options.args.assetID,{idx:idx,field:@options.args.order}),
                       name: _.template(@options.args.assetName,{idx:idx,field:@options.args.order})
                   },
                   extras: extras
                } )
                
            return this            
    
    #----------
    
    @CMSAssets: Backbone.View.extend
        tagName: "ul"
        events: { "click button": "_popup" }
        
        initialize: ->
            @_views = {}
            @collection.bind "reset", => 
                _(@_views).each (a) => $(a.el).detach(); @_views = {}
                
            @collection.bind 'add', (f) => 
                console.log "add event from ", f
                @_views[f.cid] = new AssetHost.CMSPlugin.CMSAsset({model:f,args:@options.args,rows:@options.rows})
                @render()

            @collection.bind 'remove', (f) => 
                console.log "remove event from ", f
                console.log "view is ", @_views[f.cid]
                
                if @_views[f.cid]
                    @_views[f.cid].remove()
                    delete @_views[f.cid]
                    
                @render()
                                    
            # now that all our events are up, render    
            @render()
        
        _popup: (evt) ->
            console.log("evt is ",evt)
            evt.originalEvent.stopPropagation()
            evt.originalEvent.preventDefault()
            newwindow = window.open("http://#{AssetHost.SERVER}/a/chooser", 'chooser', 'height=620,width=1000')
            
            # attach a listener to wait for the LOADED message
            window.addEventListener "message", (evt) => 
                if evt.data == "LOADED"
                    # dispatch our event with the asset data
                    newwindow.postMessage @collection.toJSON(), "http://#{AssetHost.SERVER}"
            , false
                                
            return false
        
        render: ->
            @collection.each (a) => 
                @_views[a.cid] ?= new AssetHost.CMSPlugin.CMSAsset({model:a,args:@options.args,rows:@options.rows})
            
            views = _(@_views).sortBy (a) => a.model.get("ORDER")
            $(@el).html( _(views).map (v) -> v.el )
            
            # add hiddens
            #$(@el).append(@options.hiddens)
            
            # we need to render any removed rows as empty, with extras and possibly DELETE
            if (@collection.length < @options.rows.length)
                for idx in _.range(@collection.length,@options.rows.length)
                    _(@options.rows[idx].extras).each( (ex) => 
                        $( @el ).append $("<input/>",{type:'hidden',name:ex.name,id:ex.id,value:ex.value})
                    )
                    
                    if @options.args.delete
                        $( @el ).append $("<input/>",{
                            type: "hidden",
                            id: _.template(@options.args.assetID,{idx:idx,field:@options.args.delete}),
                            name: _.template(@options.args.assetName,{idx:idx,field:@options.args.delete}),
                            value: "on"
                        })
            
            $(@el).append( $("<li/>").html( $('<button/>',{text:"Pop Up Asset Chooser"})))
            
            if @options.args.count
                if (el = $('#'+@options.args.count)[0]) and @collection.length > @options.rows.length
                    el.value = @collection.length
                            
            return this