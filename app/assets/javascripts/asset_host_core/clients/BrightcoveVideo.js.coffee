class AssetHost.Client.BrightcoveVideo
    DefaultOptions:
        playerKey:      "AQ~~,AAAAmtVKbGE~,pW41hkPiaos27C7knwyeOWQgVlG4w7v5"
        playerId:       "1247178207001"
        brightcoveJS:   "http://admin.brightcove.com/js/BrightcoveExperiences_all.js"
    
    template:
        """
        <div style="display:none"></div>

        <object id="ah_bcove_<%= videoid %>" class="BrightcoveExperience">
          <param name="bgcolor" value="#FFFFFF" />
          <param name="width" value="<%= width %>" />
          <param name="height" value="<%= height %>" />
          <param name="playerID" value="<%= playerid %>" />
          <param name="playerKey" value="<%= playerkey %>" />
          <param name="isVid" value="true" />
          <param name="isUI" value="true" />
          <param name="dynamicStreaming" value="true" />
          <param name="@videoPlayer" value="<%= videoid %>" />
        </object>
        """
    
    constructor: (el,options) ->
        @opts = _(_({}).extend(@DefaultOptions)).extend options||{}
        
        @el = $(el)
        
        # we're given an img element.  we'll stick an overlay with a play 
        # button on it, and then on click we'll launch the video
        
        # get width and height from the img
        @w = $(el).attr("width")
        @h = $(el).attr("height")
        console.log "height is #{@h} for ", el
        
        # get videoid from data-ah-videoid attribute
        @videoid = @el.attr("data-ah-videoid")
        
        console.log "Setting up for brightcove video ", @videoid
        
        # create an element off-screen for loading
        @overlay = $ "<div/>", style:"position:relative;left:0;height:0;margin:0;padding:0;border:0"
        @el.before @overlay
        @click = $ "<div/>", class:"BrightcoveVideoOverlay", style:"width:#{@w}px;height:#{@h}px"
        @overlay.append @click
        @click.bind "click", (e) => @launch()
        
    #----------
                
    launch: ->
        # render template
        @html = _.template @template, 
            width:      @w 
            height:     @h
            videoid:    @videoid
            playerid:   @opts.playerId
            playerkey:  @opts.playerKey
                    
        if window.brightcove?
            @overlay.detach()
            
            @swap()
        else
            $.getScript @opts.brightcoveJS, => 
                @overlay.detach()
                
                @swap()

    swap: ->
        wrap = $("<div/>",style:"width:#{@w}px;height:#{@h}px")
        @el.wrap wrap
        @el.replaceWith @html
        
        brightcove.createExperiences()
        