class window.AssetHostModels
    constructor: ->

    @Asset:
        Backbone.Model.extend({})
        
    @Assets: 
        Backbone.Collection.extend({
            baseUrl: "/api/assets",
            model: @Asset,
            
            initialize: ->
                _.bindAll(this, 'parse','url','nextPage','previousPage')
                
                typeof(options) != 'undefined' || (options = {});
                @page = 1;
            
            parse: (resp,xhr) ->
                @next_page = xhr.getResponseHeader('X-Next-Page')
                @total_entries = xhr.getResponseHeader('X-Total-Entries')
                console.log "Next page for assets is #{@next_page}"
                
                resp
                
            url: ->
                @baseUrl + "?" + $.param({page:@page})
                
            nextPage: ->
                if !@next_page
                    return false
                
                @page = @page + 1
                @fetch()
                
            previousPage: ->
                if @page <= 1
                    return false
                    
                @page = @page - 1
                @fetch()
        })