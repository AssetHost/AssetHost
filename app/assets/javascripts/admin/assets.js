var AssetHostUpload = Class.create({
    DefaultOptions : {
		dropEl : "filedrop",
		url : "",
		posturl : "",
		readyClass : "ready",
		uploadClass : "uploading",
		errorClass : "error",
		pendingClass : "pending",
		completeClass : "complete"
    },
    
    initialize : function(options) {
        this.options = Object.extend(
			Object.extend({},this.DefaultOptions), options || {}
		);

		this.drop = $(this.options.dropEl)
		
		//this.files = {}
		this.files = []
		this._ids = []
		this._uploading = []
		
		this.fileUL = new Element("ul",{})
		this.drop.update(this.fileUL)

		this.uploadButton = new Element("li",{class:"ahUp_upbutton"})
		this.uploadButton.update("Upload File(s)")
		this.drop.insert({bottom:this.uploadButton})
		this.uploadButton.hide()
		
		this.uploadButton.observe("click",this._uploadFiles.bindAsEventListener(this))
		
		this.drop.observe("dragenter",this._dragenter.bind(this))
		this.drop.observe("dragover",this._dragover.bind(this))
		this.drop.observe("drop",this._drop.bind(this))
		
		//alert("uploader ready")
	},
	_dragenter : function(evt) {
		evt.stopPropagation();
		evt.preventDefault();
		
		new Effect.Highlight(this.drop)
		
		return false;
	},
	_dragover : function(evt) {
		evt.stopPropagation();
		evt.preventDefault();
		return false;
	},
	_drop : function(evt) {
		evt.stopPropagation();
		evt.preventDefault();
		
		console.log( evt.dataTransfer.files );

		// do something with this info
		if (evt.dataTransfer.files.length > 0) {
			$A(evt.dataTransfer.files).each(function(f) {
				this._addFileToList(f)
			}.bind(this))			
		}
		
		return false;
	},
	
	_addFileToList : function(f) {
		if ( this._uploading.length )
			return false
		
		console.log(f)
		var li = new Element("li",{})
		li.update(f.name + " (" + this.readableFileSize(f.size) + ")")
		
		var x = new Element("span",{})
		x.insert("x")
		x.observe("click",this._removeFile.bindAsEventListener(this,obj,li))
		li.insert(x)
				
		var obj = {f:f,li:li,x:x}

		this.fileUL.insert({bottom:li})
		this.files.push(obj)
		
		this._setFileState(obj,this.options.readyClass)		
		
		this._updateUploadButton()
	},
	
	_removeFile : function(evt,obj,li) {
		if ( this._uploading.length )
			return false
		
		console.log(obj)
		Element.remove(li)
		this.files = this.files.without(obj)
		
		this._updateUploadButton()
	},
	
	_updateUploadButton : function() {
		if ( this.files.length ) {
			this.uploadButton.show()
		} else {
			this.uploadButton.hide()
		}
	},
	
	_uploadFiles : function(evt) {
		// disable drag/drop UI
		this.uploadButton.hide()
		
		// upload files
		this.files.each(function(obj) {
			this._uploading.push(obj)

			var xhr    = new XMLHttpRequest();

			var upload = xhr.upload;
			Event.observe(upload,"progress",this._onUploadProgress.bindAsEventListener(this,obj))
			Event.observe(upload,"load",this._onUploadComplete.bindAsEventListener(this,obj))
			Event.observe(upload,"error",this._onUploadError.bindAsEventListener(this,obj))
			
			xhr.onreadystatechange = this._onUploadState.bindAsEventListener(this,xhr,obj)

			xhr.open('POST',this.options.url, true);
			xhr.setRequestHeader('X_FILE_NAME', obj.f.fileName)
			xhr.setRequestHeader('CONTENT_TYPE', obj.f.type)
			xhr.setRequestHeader('HTTP_X_FILE_UPLOAD','true')
			xhr.send(obj.f);
			
			this._setFileState(obj,this.options.uploadClass)						
		}.bind(this))
		
		// redirect to meta input
		
	},
	
	_onUploadProgress : function(evt,obj) {
		if (evt.lengthComputable) {
			var percent = Math.floor( evt.loaded / evt.total * 100 )
			obj.x.update("("+percent+"%)")
		} else {
			obj.x.update("("+evt.loaded+"%)")
		}
	},
	_onUploadComplete : function(evt,obj) {
		// turn our li green or something
		this._setFileState(obj,this.options.pendingClass)		
	},
	_onUploadError : function(evt,obj) {
		// turn our li red?
		this._uploading = this._uploading.without(obj)
		this._setFileState(obj,this.options.errorClass)
	},
	_onUploadState : function(evt,req,obj) {
		// look for a response asset ID
		if (req.readyState == 4) {
			if (req.status == 200) {
				this._setFileState(obj,this.options.completeClass)
				obj.li.addClassName(this.options.completeClass)
				
				if (req.responseText != "ERROR") {
					this._ids.push(req.responseText)					
				}
				this._uploading = this._uploading.without(obj)
				
				if (!this._uploading.length) {
					this._uploadingComplete()
				}
			} else {
				// hmm... error
			}
		}
	},
	
	_uploadingComplete : function() {
		link = new Element("li",{class:""})
		link.update(
			new Element("a",{
				href: (this.options.posturl+"?ids=" + this._ids.join(","))
			}).update("Go to Metadata Entry")
		)
		this.drop.insert({bottom:link})		
	},
	
	_setFileState : function(obj,class) {
		// remove existing class(es)
		$w(obj.li.className).each(function(c) {obj.li.removeClassName(c)})
		
		obj.li.addClassName(class)
	},
	
	readableFileSize : function(size) {
	    var units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
	    var i = 0;
	    while(size >= 1024) {
	        size /= 1024;
	        ++i;
	    }
	    return size.toFixed(1) + ' ' + units[i];
	}
})