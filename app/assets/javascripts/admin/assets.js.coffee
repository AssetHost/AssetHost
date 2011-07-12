class window.AssetHostUpload
    DefaultOptions: 
        {
            dropEl: "#filedrop",
            url: "",
            posturl: "",
            readyClass: "ready",
            uploadClass: "uploading",
            errorClass: "error",
            pendingClass: "pending",
            completeClass: "complete",
            token: '',
            emptyText: "Drop File(s) Here",
            afterText: "Go to Metadata Entry",
            allowMultiple: true
        }
        
    #----------
    
    constructor: (options) ->
        @options = _(_({}).extend(this.DefaultOptions)).extend( options || {} )
        
        @drop = $(@options.dropEl)

        @files = []
        @_ids = []
        @_uploading = []

        @fileUL = $ "<ul/>"
        $(@drop).append @fileUL

        @_emptyEl = $ "<li/>", { class: "help", text: this.options.emptyText }
        $(@fileUL).append @_emptyEl
        
        @uploadButton = $ "<p/>", { class: "ahUp_upbutton", text: "Upload File(s)" }
        $(@drop).append @uploadButton
        $(@uploadButton).hide()
        $(@uploadButton).click (evt) => this._uploadFiles(evt)

        console.log "drop is ", @drop

        $(@drop).bind "dragenter", (evt) => @_dragenter(evt)
        $(@drop).bind "dragover", (evt) => @_dragover(evt)
        $(@drop).bind "drop", (evt) => @_drop(evt)
        
    #----------
                    
    _dragenter: (evt) ->
        evt.stopPropagation();
        evt.preventDefault();
        
        #new Effect.Highlight(this.drop)
        
        false
    
    #----------
    
    _dragover: (evt) ->
        evt.stopPropagation();
        evt.preventDefault();
        false
    
    #----------
    
    _drop: (evt) ->
        evt = evt.originalEvent
        
        evt.stopPropagation();
        evt.preventDefault();
        
        console.log evt.dataTransfer.files

        # do something with this info
        for f in evt.dataTransfer.files
            @_addFileToList(f)
        
        false
    
    #----------
    
    _addFileToList: (f) ->
        if ( !this.options.allowMultiple && this.files.length )
            return false
        
        if ( this._uploading.length )
            return false
        
        console.log(f)
        
        li = $ "<li/>", { text: "#{f.name} (#{@readableFileSize f.size})" }
        
        obj = {f:f,li:li,x:null}

        x = $("<span/>", { text: "x" })
            .bind "click", `_.bind(this._removeFile, this, obj, li)`
        li.append x
        
        obj.x = x       
        
        $(@fileUL).append li
        
        @files.push obj

        @_setFileState obj, this.options.readyClass
        
        @_updateUploadButton()

        true
        
    #----------
    
    _removeFile: (obj,li,evt) ->
        console.log "in removeFile for ",evt,obj,li
        
        if @_uploading.length
            return false
            
        $(li).detach()
            
        @files = _(@files).without obj
        
        @_updateUploadButton()
    
    #----------
    
    _updateUploadButton: ->
        if @files.length then $(@uploadButton).show() else $(@uploadButton).hide()
    
    #----------
    
    _uploadFiles: (evt) ->
        # disable drag/drop UI
        @uploadButton.hide()
        
        # upload files
        for obj in @files
            @_uploading.push(obj)

            xhr    = new XMLHttpRequest();

            upload = xhr.upload;
            
            $(upload).bind "progress", `_.bind(this._onUploadProgress,this,obj)`
            $(upload).bind "load", `_.bind(this._onUploadComplete,this,obj)`
            $(upload).bind "error", `_.bind(this._onUploadError,this,obj)`
            
            xhr.onreadystatechange = `_.bind(this._onUploadState,this,xhr,obj)`

            xhr.open('POST',this.options.url, true);
            xhr.setRequestHeader('X_FILE_NAME', obj.f.fileName)
            xhr.setRequestHeader('CONTENT_TYPE', obj.f.type)
            xhr.setRequestHeader('HTTP_X_FILE_UPLOAD','true')
            xhr.send(obj.f);
            
            @_setFileState obj, this.options.uploadClass
    
    #----------
    
    _onUploadProgress: (obj,evt) ->
        evt = evt.originalEvent
        
        if evt.lengthComputable
            percent = Math.floor( evt.loaded / evt.total * 100 )
            $(obj.x).text "(#{percent}%)"
        else
            $(obj.x).text "(#{evt.loaded}%)"

    #----------

    _onUploadComplete: (obj,evt) ->
        # turn our li green or something
        @_setFileState obj, @options.pendingClass

    #----------

    _onUploadError: (obj,evt) ->
        # turn our li red?
        @_uploading = _(@_uploading).without obj
        @_setFileState obj, this.options.errorClass

    #----------
    
    _onUploadState: (req,obj,evt) ->
        # look for a response asset ID
        if req.readyState == 4
            if req.status == 200
                @_setFileState obj, @options.completeClass
                $(obj.li).addClass @options.completeClass
                
                console.log "response is", req.responseText
                
                if req.responseText != "ERROR"
                    @_ids.push req.responseText
                    
                @_uploading = _(@_uploading).without obj
                
                if !@_uploading.length
                    @_uploadingComplete()
            else    
                # error
    
    #----------
                    
    _uploadingComplete: ->
        link = $("<li/>").append(
            $ "<a/>", { href: @options.posturl+"?ids="+@_ids.join(","), text: @options.afterText }
        )

        $(@drop).append link
    
    #----------
    
    _setFileState: (obj,classname) ->
        # remove existing class(es)
        
        for c in (obj.li.className || "").split(" ")
            $(obj.li).removeClass(c)
        
        $(obj.li).addClass classname
    
    #----------
    
    readableFileSize: (size) ->
        units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
        i = 0;
        
        while size >= 1024
            size /= 1024
            ++i
        
        size.toFixed(1) + ' ' + units[i];