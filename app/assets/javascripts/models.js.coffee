#= require assethost



class AssetHost.Models
    constructor: ->
        
    @Asset:
        Backbone.Model.extend({
            urlRoot: "http://#{AssetHost.SERVER}/api/assets/"
            
            modal: ->
                @_modal ?= new AssetHost.Models.AssetModalView({model: this})
                
            editModal: ->
                @_emodal ?= new AssetHost.Models.AssetEditModalView({model: this})
                
            #----------
            
            url: ->
                url = if this.isNew() then @urlRoot else @urlRoot + encodeURIComponent(@id)
                
                if AssetHost.TOKEN
                    url = url + "?" + $.param({auth_token:AssetHost.TOKEN})
                    
                url
                
            #----------
            
            chopCaption: (count=100) ->
                chopped = this.get('caption')

                if chopped and chopped.length > count
                    regstr = "^(.{#{count}}\\w*)\\W"
                    chopped = chopped.match(new RegExp(regstr))

                    if chopped
                        chopped = "#{chopped[1]}..."
                    else
                        chopped = this.get('caption')

                chopped
        })
        
    #----------
    
    @Assets:
        Backbone.Collection.extend({
            baseUrl: "/api/assets",
            model: @Asset
            
            # If we have an ORDER attribute, sort by that.  Otherwise, sort by just 
            # the asset ID.  
            comparator: (asset) ->
                asset.get("ORDER") || -Number(asset.get("id"))
            
            #----------

        })
        
    @PaginatedAssets: 
        @Assets.extend({
            
            initialize: ->
                _.bindAll(this, 'parse','url')
                
                typeof(options) != 'undefined' || (options = {});
                @_page = 1;
                @_query = ''
                @per_page = 24
                @total_entries = 0
                
                this
            
            parse: (resp,xhr) ->
                @next_page = xhr.getResponseHeader('X-Next-Page')
                @total_entries = xhr.getResponseHeader('X-Total-Entries')
                console.log "Next page for assets is #{@next_page}"
                
                resp
                
            url: ->
                @baseUrl + "?" + $.param({page:@_page,q:@_query})
                
            query: (q=null) ->
                @_query = q if q?
                @_query
                
            page: (p=null) ->
                console.log('page is ',@_page,p)
                @_page = Number(p) if p? && p != ''
                @_page                
        })
        
    #----------
    
    @AssetDropAssetView:
        Backbone.View.extend
            tagName: 'li'
            
            template:
                """
                <button class="delete small awesome red">x</button>
                <%= tags.thumb %>
                <b><%= title %></b>
                <p><%= chop %></p>
                """
            
            events:
                'click button.delete': "_remove"
                'click': '_click'
            
            #----------
                
            initialize: ->
                @drop = @options.drop
                @model.bind "change", => @render()
                @render()
                
            #----------
            
            _remove: ->
                console.log ""
                @drop.trigger 'remove', @model
                false
                
            #----------
            
            _click: (evt) ->
                if not $(evt.currentTarget).hasClass("delete")
                    @drop.trigger 'click', @model
                
            #----------
                
            render: ->
                $( @el ).html( _.template(@template,_(@model.toJSON()).extend chop:@model.chopCaption() ))
                $(@el).attr "data-asset-id", @model.get("id")
                @
    
    #----------
    
    @AssetDropView:
        Backbone.View.extend
            tagName: "ul"
            className: "assets"
                
            initialize: ->
                @_views = {}

                @collection.bind 'add', (f) => 
                    console.log "add event from ", f
                    @collection.sort()

                @collection.bind 'remove', (f) => 
                    console.log "remove event from ", f
                    @collection.sort()

                @collection.bind 'reset', (f) => 
                    console.log "reset event from ", f                    
                    _(@_views).each (av) => $(av.el).detach()
                    @_views = {}
                    @render()
                
            #----------
                        
            render: ->
                # set up views for each collection member
                @collection.each (f) => 
                    # create a view unless one exists
                    @_views[f.cid] ?= new Models.AssetDropAssetView({model:f,drop:@})

                # make sure all of our view elements are added
                $(@el).append( _(@_views).map (v) -> v.el )

                $( @el ).sortable
                    update: (evt,ui) => 
                        console.log "ui is ",ui
                        console.log "ul children is ",evt.target.children
                        _(evt.target.children).each (li,idx) => 
                            id = $(li).attr('data-asset-id')
                            @collection.get(id).attributes.ORDER = idx
                            console.log("set idx for #{id} to #{idx}")
                        @collection.sort()

                @
        
    #----------
            
    @AssetSearchView:
        Backbone.View.extend({
            className: "search_box"

            template:
                '''
                <input type="text" style="width: 200px" value="<%= query %>"/>
                <button class="large awesome orange">Search</button>
                '''
                
            events: {
                'click button': 'search',
                'keypress input:text': '_keypress'
            }

            initialize: ->
                @collection.bind('all', => @render() )
                        
            _keypress: (e) ->
                if e.which == 13
                    @search()
                
            search: ->
                query = $( @el ).find("input")[0].value
                console.log "in search for ", query
                @trigger "search", query
                
            render: ->
                $(@el).html _.template @template, query:@collection.query()
                return this
        })
        
    #----------
    
    @AssetBrowserAssetView:
        Backbone.View.extend({
            tagName: "li"
            template:
                '''
                <button data-asset-url="<%= url %>" draggable="true"><%= tags.thumb %></button>
                '''
                
            tipTemplate:
                '''
                <h3><%= title %></h3>
        		<%= owner %>
        		<br/><%= size %>                
                '''
                
            initialize: ->
                @id = "ab_#{@model.get('id')}"
                $(@el).attr("data-asset-url",@model.get('url'))

                @render()
                
                $(@el).find('button')[0].addEventListener "click",
                    (evt) => @trigger "click", @model
                    true
                    
                # add tooltip
                $(@el).tooltipsy
                    alignTo: 'element'
                    content: _.template @tipTemplate, @model.toJSON()
                                
                @model.bind "change", => @render()
                                
            render: ->
                $( @el ).html _.template @template, @model.toJSON() 
                $(@el).attr "draggable", true
                return this
        })
        
    #----------
    
    @AssetBrowserView:
        Backbone.View.extend({
            tagName: "ul"
            
            initialize: ->
                @_views = {}
                @collection.bind "reset", => 
                    _(@_views).each (a) => $(a.el).detach()
                    @_views = {}
                    @render()
                            
            pages: ->
                @_pages ?= (new AssetHost.Models.PaginationLinks(@collection)).render()
                
            loading: ->
                $(@el).fadeOut()
            
            render: ->
                # set up views for each collection member
                @collection.each (a) => 
                    # create a view unless one exists
                    @_views[a.cid] ?= new AssetHost.Models.AssetBrowserAssetView({model:a})
                    @_views[a.cid].bind "click", (a) => @trigger "click", a
                    
                # make sure all of our view elements are added
                $(@el).append( _(@_views).map (v) -> v.el )
                
                # clear loading status
                $(@el).fadeIn()
            
                return this
        })
        
    #----------
    
    @AssetModalView:
        Backbone.View.extend({
            events: 
                'click button.select': '_select'
                'click button.admin': '_admin'
                
            template:
                '''
                <div class="ah_asset_browse">
                    <%= tags.lead %>
                    <h1><%= title %></h1>
                    <h2><%= owner %></h2>
                    <h2><%= size %></h2>
                    <p><%= caption %></p> 
                                    
                    <% if (admin) { %><button class="admin medium awesome yellow">View in Admin</button><% }; %>
                    <% if (select) { %><button class="select large awesome orange">Select Asset</button><% }; %>
                </div>
                '''

            open: (options) ->
                @options = options || {}
                console.log "modal options is ", @options
                
                $(@render().el).dialog(_(_({}).extend({
                    modal: true,
                    width: 600
                })).extend( @options.options || {} ))
                
            close: ->
                $(@el).dialog('close')
            
            _select: ->
                @close()
                @model.trigger('selected',@model)    
            
            _admin: ->
                @close()
                @model.trigger('admin',@model)
            
            render: ->
                $( @el ).html _.template @template,_(@model.toJSON()).extend
                    select: if @options.select? then @options.select else true
                    admin: if @options.admin? then @options.admin else false
            
                return this
        })
        
    #----------
    
    @AssetEditModalView:
        Backbone.View.extend({
            template:
                '''
                <div class="ah_asset_edit">
                    <%= tags.lead %>
                    <h1><%= title %></h1>
                    <h2><%= owner %></h2>
                    
                    <textarea rows="4" style="width: 100%"><%= caption %></textarea>
                    <button class="save large awesome orange">Save Caption</button>
                    <button class="admin medium awesome yellow">View in Admin</button>
                </div>
                '''
                
            events:
                'click button.save': '_save'
                'click button.admin': '_admin'
            
            open: (options) ->
                $(@render().el).dialog(_(_({}).extend({
                    modal: true,
                    width: 350
                })).extend( options || {} ))
                
            close: ->
                $(@el).dialog('close')
            
            _save: -> 
                caption = $( @el ).find("textarea")[0].value
                @model.set({caption:caption})
                @close()
            
            _admin: -> 
                window.open("/a/assets/#{@model.get('id')}") 
                
            render: ->
                $( @el ).html( _.template(@template,@model.toJSON()))
            
                return this
        })
        
    #----------
    
    @SaveAndCloseView:
        Backbone.View.extend
            events: { 'click button': 'saveAndClose' }
            initialize: ->
                @collection.bind "all", => @render()                
                @render()
            
            template:
                '''
                <button id="saveAndClose" class="large awesome orange">
                    Save and Close
                    <% if (count) { %>(<%= count %> Assets)<% } %>
                </button>
                '''
            
            saveAndClose: ->
                console.log "saveAndClose Clicked with ",@collection
                
                # make sure collection is sorted before we return it
                @collection.sort()
                @trigger 'saveAndClose', @collection.toJSON()
            
            render: ->
                $( @el ).html _.template(@template,{count:@collection.size()})
                return @
        
    #----------
        
    @PaginationLinks:
        Backbone.View.extend({
            DefaultOptions:
                {
                    inner_window: 4,
                    outer_window: 1,
                    prev_label: "&#8592; Previous",
                    next_label: "Next &#8594;",
                    separator: " ",
                    spacer: "<li class='spacer'>...</li>"
                }
            
            events: { 'click li': 'clickPage' }
            
            initialize: (collection,options) ->
                @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )

                @collection = collection
                @collection.bind("reset", => @render() )
                @collection.bind("add", => @render() )
                @collection.bind("change", => @render() )

            #----------
            
            template:
                '''
                <ul class="pages">
                <% if (current > 1) { %>
                    <li data-page="<%= current - 1 %>" class="prev"><%= options.prev_label %></li>
                <% } %>
                <%= links %>
                <% if ( current + 1 <= pages ) { %>
                    <li data-page="<%= current + 1 %>" class="next"><%= options.next_label %></li>
                <% } %>
                </ul>
                '''
                
            linkTemplate:
                '''
                <li data-page="<%= page %>" <% if (current) { %>class="current"<% } %> ><%= page %></li>
                '''
                
            clickPage: (evt) ->
                page = $(evt.currentTarget).attr("data-page")
                
                if page
                    console.log "in clickPage for ",page
                    @trigger "page", page
            
            render: -> 
                # what pages are we displaying?
                pages = Math.floor( @collection.total_entries / @collection.per_page + 1)
                current = @collection._page
                
                console.log "current / total pages: ", current, pages
                
                rendered = {}
                links = []
                
                # start with outer_window from 1
                _(_.range(1,1+@options.outer_window)).each( (i) => 
                    links.push _.template( @linkTemplate, {page:i,current:(current==i)} )
                    rendered[ i ] = true
                )
                
                # now try -inner_window from current
                _(_.range(current-@options.inner_window,current)).each( (i) =>
                    if i > 0 && !rendered[ i ]
                        if i-1 > 0 && !rendered[i-1]
                            links.push @options.spacer
                        
                        links.push _.template( @linkTemplate, {page:i,current:false} )
                        rendered[ i ] = true
                )
                
                # now try current
                if !rendered[ current ]
                    if current-1 > 0 && !rendered[current-1]
                        links.push @options.spacer
                        
                    links.push _.template( @linkTemplate, {page:current,current:true} )
                    rendered[ current ] = true
                
                # now try +inner_window from current
                _(_.range(current+1,current+@options.inner_window+1)).each( (i) =>
                    if i < pages && !rendered[ i ]
                        if i-1 > 0 && !rendered[i-1]
                            links.push @options.spacer
                            
                        links.push _.template( @linkTemplate, {page:i,current:false} )
                        rendered[ i ] = true
                )
                                
                # and finally, -outer_window from last page
                _(_.range(pages+1-@options.outer_window,pages+1)).each( (i) => 
                    if i > 0 && !rendered[ i ]
                        if i-1 > 0 && !rendered[i-1]
                            links.push @options.spacer
                        
                        links.push _.template( @linkTemplate, {page:i,collection:@collection,current:(current==i)} )
                        rendered[ i ] = true
                )
                                
                $( @el ).html( _.template(@template,{ current: current, pages: pages, links: links.join(@options.separator), options: @options }))
                
                this
        })
        
    #----------
        
    @queuedSync: (method,model,success,error) ->
        console.log "in sync"

    @QueuedFile:
        Backbone.Model.extend({
            sync: @queuedSync

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

                @xhr.open('POST',this.collection.urlRoot, true);
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
        Backbone.Collection.extend
            model: @QueuedFile
            urlRoot: "/a/assets/upload"
            
            initialize: (models,options) ->
                @urlRoot = options.urlRoot

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
                <% if (!xhr) { %>
                    <button class="remove small awesome red">x</button>
                    <button class="upload small awesome green">Upload</button>
                <% }; %>
                <% if (STATUS == 'uploading') { %>
                    <b>(<%= PERCENT %>%)</b>
                    <br/>
                <% }; %>
                <%= name %>: <%= size %> 
                '''

            initialize: ->
                @model.bind "change", => @render()
                
                @img = ''

                # try to read file on disk
                file = @model.get('file')
                if file.type.match('image.*')
                    reader = new FileReader()
                    
                    reader.onload = (e) => 
                        console.log "got reader.onload for ", e
                        @img = $ "<img/>", {
                            class: "thumb",
                            src: e.target.result,
                            title: file.name
                        }
                        
                        m = /^([^,]+),(.*)$/.exec(e.target.result)
                        @exif = EXIF.readFromBinaryFile(window.atob(m[2]))
                                                    
                        @render()
                        
                    reader.readAsDataURL(file)

                @render()

            _remove: (evt) ->
                console.log "calling remove for ",this
                @model.collection.remove(@model)    

            _upload: (evt) ->
                @model.upload()

            render: ->
                $( @el ).attr('class',@model.get("STATUS"))

                $( @el ).html( _.template(@template,{
                    exif: @exif,
                    name: @model.get('name'),
                    size: @model.readableSize(),
                    STATUS: @model.get('STATUS'),
                    PERCENT: @model.get('PERCENT'),
                    xhr: if @model.xhr then true else false
                }))
                
                if @img
                    $( @el ).prepend( @img )

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
                    @_views[f.cid] = new Models.QueuedFileView({model:f})
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
                    @_views[f.cid] ?= new Models.QueuedFileView({model:f})

                # make sure all of our view elements are added
                $(@el).append( _(@_views).map (v) -> v.el )
                console.log "rendered files el is ",@el

                return this
        })