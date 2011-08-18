#= require assethost
#= require backbone.modelbinding

class AssetHost.AssetAdmin
    DefaultOptions:
        el: ""
        replace: ''
        replacePath: ''
        
    constructor: (asset,options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
        
        @asset = new AssetHost.Models.Asset(asset)
        @preview = new AssetAdmin.PreviewView({model: @asset})
        @form = new AssetAdmin.FormView({model: @asset})
        $( @options.el ).html(@preview.el)
        
        if @options.replace
            # set up replace image uploader
            @chooser = new AssetHost.ChooserUI
                dropEl: @options.replace
                assets: false
                uploads: true
                limit: 1
                uploadPath: @options.replacePath
                saveButton: false
                
    #----------
        
    @FormView:
        Backbone.View.extend({
            el: "#editform"
            initialize: ->
                #Backbone.ModelBinding.call(this)    
        })
        
    #----------
    
    @PreviewView:
        Backbone.View.extend({
            template: 
                """
                <h1><%= title || image_file_name %></h1>
                <%= tags[ tag ] %>
                
                <ul class="asset_sizes">
                <% _(sizes).each(function(v,k) { %> 
                    <li data-size="<%= k %>" <% if (tag == k) {%>class="selected"<% }; %>><h1><%= k %></h1> (<%= v.width %>x<%= v.height %>)</li>
                <% }); %>
                </ul>
                <br class="clear"/>
                """
                
            events:
                {
                    'click li': '_sizeClick'
                }

            initialize: -> 
                @size = "wide"
                @render()

            _sizeClick: (evt) ->
                console.log "got click with evt ", evt
                size = $(evt.currentTarget).attr("data-size")
                
                if size != @size
                    @size = size
                    @render()

            render: -> 
                data = _(_({}).extend(@model.toJSON())).extend({tag:@size})
                console.log("data is ",data)
                $( @el ).html _.template(@template, data)
                return this
        })
            
            
        