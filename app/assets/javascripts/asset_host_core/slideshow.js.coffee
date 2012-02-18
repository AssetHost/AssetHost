#= require ./assethost
#= require backbone
#= require ./models

class AssetHost.Slideshow
    DefaultOptions:
        el: "#photo"
        initial: 4
        start: 0
        imgwidth: null
        imgheight: null
        margin: 12
        
    constructor: (options) ->
        @options = _(_({}).extend(@DefaultOptions)).extend options||{}
        
        # add in events
        _.extend(this, Backbone.Events)

        $ => 
            # -- create hidden element for dimensioning -- #
            @hidden = $ "<div/>", style:"position:absolute; top:-10000px; width:0px; height:0px;"
            $('body').append @hidden

            # -- get our parent element -- #
            
            @el = $ @options.el
        
            # -- create asset collection -- #
            
            @assets = new Slideshow.Assets @options.assets
            
            # -- create our nav buttons -- #
            
            @nav = new Slideshow.NavigationLinks current:@options.start,total:@assets.length
            
            # -- set up our slides -- #
        
            @slides = new Slideshow.Slides 
                collection: @assets
                hidden:     @hidden
                initial:    @options.initial
                imgwidth:   @options.imgwidth
                imgheight:  @options.imgheight
                nav:        @nav
                margin:     @options.margin
                
            @el.html @slides.el
            @slides.render()
            
            # -- bind slides and nav together -- #
            @nav.bind "slide", (idx) => @slides.slideTo(idx)
            @slides.bind "slide", (idx) => 
                @nav.setCurrent idx
                @trigger "slide", idx

    #----------
    
    @Asset:
        Backbone.Model.extend
            initialize: ->
                # do something
        
    @Assets:
        Backbone.Collection.extend
            url: "/"
            model: @Asset
    
    #----------
    
    @Slide:
        Backbone.View.extend
            tagName: 'li'
            className: "slide"
                
            template:
                '''
                <div class="text" style="width: <%= width %>px;margin: 0 auto">
                    <div class="credit"><%= credit %></div>
                    <p><%= caption %></p>
                </div>
                '''
                
            fullTemplate:
                '''
                
                '''
            
            #----------
                
            initialize: ->
                @slides = @options.slides
                @hidden = @options.hidden
                @index = @options.index
                
            #----------    
                
            render: ->
                # -- choose image size -- #
                
                # sort of sizes hash
                sizes = @model.get("sizes")
                _(sizes).each (v, k) => v.key = k 
                sizes = _(sizes).sortBy (v) -> -v.width                
                
                # now take the first size that fits
                @imgSize = _(sizes).find (v,i) =>
                    if v.width <= $(@el).width()
                        # take it
                        return true
                    else
                        return false
                                        
                # -- render text elements -- #
                
                # we have to render twice...  once to hidden and once to @el. 
                # this allows us to get dimensions
                
                # create temp element and render
                tmp = $ "<div/>", width:@imgSize.width
                
                $(tmp).html _.template @template, 
                    credit:     @model.get("credit")
                    caption:    @model.get("caption")
                    url:        @model.get("url")
                    width:      @imgSize.width
                    
                @hidden.append tmp
                
                # get dimensions
                @textHeight = $(tmp).height()                
                @imgHeight = if $(@el).height() then $(@el).height() - @textHeight else @imgSize.height
                                
                # and remove...
                $(tmp).detach()
                
                # now render caption and credit for real
                $(@el).html _.template @template, 
                    credit:     @model.get("credit")
                    caption:    @model.get("caption") 
                    url:        @model.get("url")
                    width:      @imgSize.width
                    
                # -- determine final image size -- #
                
                # because we're choosing our image based on horizontal space, 
                # we should only have to do our scaling off the vertical size
                
                imgh = @imgSize.height
                @scale = 1
                
                if imgh > @imgHeight
                    vs = @imgHeight / imgh
                    
                    if vs < 1
                        @scale = vs
                        
                # -- create img div with final dimensions -- #
                
                @imgDiv = $ "<div/>", 
                    class:"ah_imgholder"
                    style:"width:#{@imgSize.width * @scale}px;height:#{@imgSize.height * @scale}px"
                    
                $(@el).prepend @imgDiv
                                                            
                @
                
            #----------
                
            loadImage: ->
                if @slides.current == @index then $(@el).fadeOut() else $(@el).hide()
                
                @img = $ "<img/>", 
                    src:    @model.get("urls")[@imgSize.key]
                    width:  @imgSize.width * @scale
                    height: @imgSize.height * @scale
                
                @hidden.append @img
                @img.load (evt) =>
                                  
                    # -- center -- #
                    
                    @imgDiv.css "margin-left", ($(@el).width() - @img.width())/2
                    @imgDiv.css "margin-top", (@imgHeight - @img.height())/2
                    
                    # -- add to our element -- #
                    
                    @img.detach()                    
                    @imgDiv.html @img
                    
                    if @slides.current == @index then $(@el).fadeIn('slow') else $(@el).show()
                    
                    # -- tell the loader that we're done -- #
                    
                    @trigger "imgload"
    
    #----------                
    
    @Slides:
        Backbone.View.extend
            className: "slideview"

            events:
                'mouseover': '_mouseover'
                'mouseout': '_mouseout'

            initialize: ->
                @hidden = @options.hidden
                @slides = []
                
                @collection.each (a,idx) => 
                    s = new Slideshow.Slide model:a, slides:@, hidden:@hidden, index:idx
                    @slides[idx] = s
                
                # we need to know the text height of our first slide to 
                # dimension space for the rest of the slides
                s = @slides[0]
                $(s.el).css "width", @options.imgwidth+"px"
                s.render()
                txth = s.textHeight
                
                @swidth = @options.imgwidth
                @sheight = @options.imgheight + txth
                
                console.log "slide height should be ", @sheight
                
                @queued = []
                @loaded = []
                @active = false
                
                @current = null
                
                @hasmouse = false
                
                $(window).bind "keydown", (evt) => @_keyhandler(evt)
            
            #----------
                
            render: () ->
                #$(@el).css "position", "absolute"                
                $(@el).attr "tabindex", -1

                $(@el).css "width", @swidth+"px"

                totalw = @collection.length * @swidth

                # check if slide0 has a right margin, and adjust width accordingly
                if @options.margin
                    totalw = totalw + @collection.length * @options.margin
                                    
                # height defaults to slide height
                svheight = @sheight
                
                if @options.nav
                    $(@el).html @options.nav.el
                    @options.nav.render()
                    
                    navh = $(@options.nav.el).outerHeight()
                    
                    # add nav height to slideview height
                    svheight = svheight + navh

                # now set height...
                $(@el).css "height", svheight+"px"
                
                # create view tray
                @view = $ '<ul/>', style:"position:relative;width:#{totalw}px;height:#{@sheight}px"
                
                # drop view into element
                $(@el).prepend @view
                
                # add our slides                
                _(@slides).each (s,idx) => 
                    s.bind "imgload", => @_loaded s, idx
                    $(s.el).css "width", @swidth+"px"
                    $(s.el).css "height", @sheight+"px"                    
                    $(s.el).css "left", @swidth*idx + (@options.margin||0)*idx + "px"
                        
                    $(@view).append s.render().el
                    
                # create our load queue
                @queueSlides _.range 0,4 
            
            #----------
            
            _mouseover: (e) ->
                @hasmouse = true
                
            _mouseout: (e) ->
                @hasmouse = false

            _keyhandler: (e) ->
                if @hasmouse                
                    # is this a keypress we care about?
                    if e.which == 37
                        @slideBy(-1)
                    else if e.which == 39
                        @slideBy(1)

            #----------
            
            slideTo: (idx) ->                
                # figure out where slide[idx] is at
                @view.stop().animate {left: -$(@slides[idx].el).position().left}, "slow"
                @current = idx
                
                @trigger "slide", idx
                
                @_updateLoadQueue()
            
            #----------

            slideBy: (idx) ->
                t = @current + idx
                
                if @slides[t]
                    @slideTo(t)

            #----------
            
            queueSlides: (indexes...) -> 
                _(_(indexes).flatten()).each (i) =>
                    if !@loaded[i] || @loaded[i] == 0 && !_(@queued).contains(i)
                        console.log "queuing #{i}"
                        @queued.push i

                if !@active
                    @_fireUpQueue()
            
            #----------
            
            _updateLoadQueue: ->
                if !@loaded[@current] || @loaded[@current] == 0
                    @queued.unshift @current
                    
                toQueue = []
                _(_.range(@current+1,@current+4)).each (i) => toQueue.push(i) if @slides[i] 
                _(_.range(@current-2,@current)).each (i) => toQueue.push(i) if @slides[i]
            
                @queueSlides toQueue
            
            #----------
                  
            _fireUpQueue: ->
                return false if !@queued || @queued.length == 0
            
                console.log "_fireUpQueue with queue of #{@queued}"
            
                i = @queued.shift()
                s = @slides[i]
                
                if !@loaded[i] || @loaded[i] == 0
                    console.log "triggering load on #{i}"
                    @loaded[i] = 1
                    @active = i
                    s.loadImage()
                else
                    @_fireUpQueue()
            
            #----------
                    
            _loaded: (s,idx) ->
                console.log "got _loaded for #{idx}"
                @loaded[idx] = 2
                
                if @active == idx
                    @active = null
                    @_fireUpQueue()
                    
    #----------
    
    @NavigationLinks:
        Backbone.View.extend
            className: "nav"
                
            events: 
                'click button': '_buttonClick'
        
            template:
                '''
                <div style="width: 15%;">
                    <button <% print(prev ? "data-idx='"+prev+"' class='prev-arrow'" : "class='disabled prev-arrow'"); %> >Prev</button>
                </div>
                <div class="buttons" style="width:70%;"></div>
                <div style="width: 15%">
                    <button <% print(next ? "data-idx='"+next+"' class='next-arrow'" : "class='disabled next-arrow'"); %> >Next</button>
                </div>
                <br style="clear:both;line-height:0;height:0"/>
                '''
              
            #----------
            
            initialize: ->
                @total = @options.total
                @current = Number(@options.current) + 1
                
                @render()
                
            #----------
            
            _buttonClick: (evt) ->
                idx = $(evt.currentTarget).attr "data-idx"
                
                if idx
                    idx = Number(idx) - 1
                    console.log "nav trigger slide to #{idx}"
                    @trigger "slide", idx
            
            #----------
            
            setCurrent: (idx) ->
                @current = Number(idx) + 1
                console.log "nav set current to #{@current}"
                @render()
            
            #----------
                
            render: ->
                buttons = _([1..@total]).map (i) =>
                    $("<button/>", {"data-idx":i, text:i, class:if @current == i then "current" else ""})[0]
                 
                $(@el).html _.template @template, 
                    current:    @current, 
                    total:      @total,
                    prev:       if @current - 1 > 0 then @current - 1 else null
                    next:       if @current + 1 <= @total then @current + 1 else null
                   
                @$(".buttons").html buttons    