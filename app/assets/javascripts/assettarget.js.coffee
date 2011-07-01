class window.AssetHostTarget
    DefaultOptions:
        {
            dropEl: "assetdrop",
            server: "localhost:3000"
        }

    constructor: (options) ->
        @options = Object.extend(Object.extend({},this.DefaultOptions), options || {})
        
        @drop = $( @options['dropEl'] )
        
        # attach drag-n-drop listeners
        @drop.observe "dragenter", (evt) => @_dragEnter evt
        @drop.observe "dragover", (evt) => @_dragOver evt
        @drop.observe "drop", (evt) => @_drop evt
        
    getDrop: ->
        @options['dropEl']
        
    _dragEnter: (evt) ->
        console.log "In _dragEnter"
        evt.stopPropagation()
        evt.preventDefault()
        false
    
    _dragOver: (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        false
    
    _drop: (evt) ->
        console.log "drop evt: ", evt 
        console.log "uri-list is ", evt.dataTransfer.getData('text/uri-list')
		
        evt.stopPropagation()
        evt.preventDefault()
        false
    