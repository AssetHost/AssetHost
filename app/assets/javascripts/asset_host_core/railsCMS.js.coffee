#= require asset_host_core/assethost
#= require asset_host_core/models

class AssetHost.railsCMS
    DefaultOptions:
        el: ""
        preview: true

    #----------

    constructor: (assetdata,options) ->
        @options = _.defaults options||{}, @DefaultOptions
        
        # add in events
        _.extend @, Backbone.Events
                
        # -- load assets -- #
        
        @assets = new AssetHost.Models.Assets assetdata

        # -- initialize our views -- #
        
        @assetsView = new railsCMS.CMSAssets collection:@assets
        $(@options.el).html @assetsView.el
        
        window.addEventListener "message", (evt) => 
            if evt.data != "LOADED"
                console.log "got reply of ", evt
                
                found = {}
                
                # reconcile our asset list to the returned list
                _(evt.data).each (a,i) =>
                    # do we have this asset?
                    if asset = @assets.get(a.id)
                        # yes... check for changed caption
                        asset.set caption:a.caption, ORDER:i
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
                    
                @trigger("assets",evt.data)
        , false
    
    #----------
    
    @CMSAsset:
        Backbone.View.extend
            tagName: "li"
            
            template:
                '''
                <%= asset.tags[ AssetHost.SIZES.thumb ] %>
                <b><%= asset.title %> (<%= asset.size %>)</b>
                <p><%= asset.caption %></p>
                '''
            
            #----------
            
            initialize: ->
                @render()
                $(@el).attr("data-asset-url",@model.get('api_url'))
                @model.bind "change", => @render()

            #----------

            render: ->
                if @model.get('tags')                                                                                
                    $( @el ).html _.template @template,asset:@model.toJSON()
                    
                return this            
    
    #----------
    
    @CMSAssets:
        Backbone.View.extend
            tagName: "ul"
            events: { "click button": "_popup" }
            
            initialize: ->
                @_views = {}
                @collection.bind "reset", => 
                    _(@_views).each (a) => $(a.el).detach(); @_views = {}
                    
                @collection.bind 'add', (f) => 
                    console.log "add event from ", f
                    @_views[f.cid] = new railsCMS.CMSAsset({model:f,args:@options.args,rows:@options.rows})
                    @render()

                @collection.bind 'remove', (f) => 
                    console.log "remove event from ", f
                    $(@_views[f.cid].el).detach()
                    delete @_views[f.cid]
                    @render()
                
                    
                @render()
                
            #----------
            
            _popup: (evt) ->
                console.log("evt is ",evt)
                evt.originalEvent.stopPropagation()
                evt.originalEvent.preventDefault()
                newwindow = window.open("#{AssetHost.SERVER}#{AssetHost.PATH_PREFIX}/a/chooser", 'chooser', 'height=620,width=1000')
                
                # attach a listener to wait for the LOADED message
                window.addEventListener "message", (evt) => 
                    if evt.data == "LOADED"
                        # dispatch our event with the asset data
                        newwindow.postMessage @collection.toJSON(), "#{AssetHost.SERVER}"
                , false
                                    
                return false
                
            #----------
            
            render: ->
                @collection.each (a) => 
                    @_views[a.cid] ?= new railsCMS.CMSAsset({model:a,args:@options.args,rows:@options.rows})
                
                views = _(@_views).sortBy (a) => a.model.get("ORDER")
                $(@el).html( _(views).map (v) -> v.el )
                
                $(@el).append( $("<li/>").html( $('<button/>',{text:"Pop Up Asset Chooser"})))
                                                
                return this