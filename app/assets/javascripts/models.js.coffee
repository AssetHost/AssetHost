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
            
            chopCaption: (count=100) ->
                chopped = this.get('description')

                if chopped and chopped.length > count
                    regstr = "^(.{#{count}}\\w*)\\W"
                    chopped = chopped.match(new RegExp(regstr))

                    if chopped
                        chopped = "#{chopped[1]}..."
                    else
                        chopped = this.get('description')

                chopped
        })
        
    #----------
    
    @Assets:
        Backbone.Collection.extend({
            baseUrl: "/api/assets",
            model: @Asset
        })
        
    @PaginatedAssets: 
        Backbone.Collection.extend({
            baseUrl: "/api/assets",
            model: @Asset,
            
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
    
    @AssetDropView:
        Backbone.View.extend({
            tagName: "ul"
            className: "assets"
                
            events:
                {
                    'click li button': '_remove',
                    'click li': '_click'
                }
                
            initialize: ->
                @collection.bind("reset", => @render() )
                @collection.bind("add", => @render() )
                @collection.bind("change", => @render() )
                @collection.bind("remove", => @render() )
            
            template:
                '''
                <% assets.each(function(a) { %>
                    <li data-asset-id="<%= a.get('id') %>">
                        <button class="delete small awesome red">x</button>
                        <%= a.get('tags').thumb %>
                        <b><%= a.get('title') %></b>
                        <p><%= a.chopCaption() %></p>
                    </li>
                <% }); %>
                '''
                        
            _remove: (evt) -> 
                @trigger 'remove', @collection.get( $(evt.currentTarget.parentElement).attr('data-asset-id') )
                false
            
            _click: (evt) ->
                @trigger 'click', @collection.get( $(evt.currentTarget).attr('data-asset-id') )
            
            render: ->
                console.log "rendering myassets"
                $( @el ).html( _.template(@template,{assets:@collection}))
                $( @el ).find("ul").sortable({
                    update: (evt,ui) => 
                        ids = _(evt.target.children).map (li) -> $(li).attr('data-asset-id')
                        console.log("new order is ",ids)
                })
                this
        })
        
    #----------
            
    @AssetSearchView:
        Backbone.View.extend({
            initialize: ->
                @collection.bind('all', => @render() )
            
            template:
                '''
                <div class="search_box">
                <input type="text" style="width: 150px" value="<%= query %>"/>
                <button class="large awesome orange">Search</button>
                '''
                
            events: {
                'click button': 'search'
            }
            
            search: ->
                query = $( @el ).find("input")[0].value
                console.log "in search for ", query
                @trigger "search", query
                
            render: ->
                $( @el ).html( _.template(@template,{query:@collection.query()}))
                return this
        })
        
    #----------
    
    @AssetBrowserAssetView:
        Backbone.View.extend({
            tagName: "li"
            template:
                '''
                    <button><%= tags.thumb %></button>
                    <span id="asset_tip_<%= id %>" style="display: none">
                        <h3><%= title %></h3>
                		<%= owner %>
                		<br/><%= size %>            		
                    </span>          
                '''
                
            initialize: ->
                @id = "ab_#{@model.get('id')}"
                $(@el).attr("data-asset-url",@model.get('url'))

                @render()
                
                $(@el).find('button')[0].addEventListener(
                    "click", 
                    (evt) => console.log("click on ",@model);@model.modal().open(), 
                    true
                )
                                
                @model.bind "change", => @render()
                                
                                
            render: ->
                $( @el ).html( _.template @template, @model.toJSON() )
                return this
        })
        
    #----------
    
    @AssetBrowserView:
        Backbone.View.extend({
            tagName: "ul"
            
            initialize: ->
                @_views = {}
                @collection.bind "reset", => 
                    _(@_views).each (a) => $(a.el).detach(); @_views = {}
                            
            pages: ->
                @_pages ?= (new AssetHost.Models.PaginationLinks(@collection)).render()
            
            render: ->
                # set up views for each collection member
                @collection.each (a) => 
                    # create a view unless one exists
                    @_views[a.cid] ?= new AssetHost.Models.AssetBrowserAssetView({model:a})
                
                # make sure all of our view elements are added
                $(@el).append( _(@_views).map (v) -> v.el )
            
                return this
        })
        
    #----------
    
    @AssetModalView:
        Backbone.View.extend({
            events: { 'click button.select': 'select' }
            template:
                '''
                <div class="ah_asset_browse">
                    <%= tags.lead %>
                    <h1><%= title %></h1>
                    <h2><%= owner %></h2>
                    <h2><%= size %></h2>
                    <p><%= description %></p> 
                
                    <button class="select large awesome orange">Select Asset</button>
                </div>
                '''

            open: (options) ->
                $(@render().el).dialog(_(_({}).extend({
                    modal: true,
                    width: 600
                })).extend( options || {} ))
                
            close: ->
                $(@el).dialog('close')
            
            select: ->
                @close()
                @model.trigger('selected',@model)    
            
            render: ->
                $( @el ).html( _.template(@template,@model.toJSON()))
            
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
                    
                    <textarea rows="4" style="width: 100%"><%= description %></textarea>
                    <button class="large awesome orange">Save Caption</button>
                </div>
                '''
                
            events: { 'click button': 'save_caption' }
            
            open: (options) ->
                $(@render().el).dialog(_(_({}).extend({
                    modal: true,
                    width: 350
                })).extend( options || {} ))
                
            close: ->
                $(@el).dialog('close')
            
            save_caption: -> 
                caption = $( @el ).find("textarea")[0].value
                @model.set({description:caption})
                @close()
                
            render: ->
                $( @el ).html( _.template(@template,@model.toJSON()))
            
                return this
        })
        
    #----------
    
    @SaveAndCloseView:
        Backbone.View.extend({
            events: { 'click button': 'saveAndClose' }
            initialize: ->
                @collection.bind("reset", => @render() )
                @collection.bind("add", => @render() )
                @collection.bind("change", => @render() )
                @collection.bind("remove", => @render() )
            
            template:
                '''
                <button id="saveAndClose" class="large awesome orange">
                    Save and Close
                    <% if (count) { %>(<%= count %> Assets)<% } %>
                </button>
                '''
            
            saveAndClose: ->
                console.log "saveAndClose Clicked with ",@collection
                @trigger('saveAndClose',@collection.toJSON())
            
            render: ->
                $( @el ).html( _.template(@template,{count:@collection.size()}))
                return this
        })
        
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