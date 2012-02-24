# AssetHost

AssetHost is an attempt to create a one-stop-shop for hosting and linking 
to media assets that are intended for inclusion in news stories.  The goal is 
to create a hub that multiple frontend CMS systems can hook into, querying 
images, videos and documents from one source and enabling the easier 
interchange of data.

# Philosophy

AssetHost is built around the idea that all web media assets need to 
have a static visual fallback, either to support limited-functionality 
devices or to support rendering of rich media assets in contexts where 
a rich implementation isn't desired.

AssetHost is intended to run as two pieces: a backend asset server and 
lightweight frontend plugins that attach to the CMS system.  The pieces 
should speak to each other using a secure API.

### Backend Engine

This repository provides the AssetHostCore engine, which can be run either 
on the root of a standalone application (perhaps powering multiple frontend 
applications) or at a namespace in an existing application.

The backend server provides the primary UI for uploading, managing, and  
serving assets. It also provides an API endpoint that can be accessed either 
by the local application (this is how much of the admin works) or by other 
applications or plugins.

A sample host application can be found at <http://github.com/SCPR/AssetHostApp>

### Plugins for Other Applications

AssetHost provides an API and a Chooser UI that can be integrated into 
your application, allowing you to integrate the system in a minimal amount 
of code.

_TODO: More documentation on CMS interaction. External Rails example. Django example._

### Integrating with the AssetHost engine

To integrate with a locally-installed AssetHostCore engine, simply make your 
mapping data model belong to AssetHostCore::Asset.

_TODO: More documentation on creating content/asset models._

### Workflow

1. Photographer / Author / Editor goes to AssetHost and uploads or imports 
a media asset.

2. Author / Editor goes to their frontend CMS and uses the plugin UI to 
select the asset they want to attach to their content (which might be a 
story, a blog post, etc).

3. CMS plugin uses API to query AssetHost and retrieve presentation code 
for the asset.  

4. The CMS should call new AssetHost.Client() to put in place the handler 
for rich assets.

4. The CMS should display the image asset.  If it contains tags for a 
rich asset, the Client library will catch it and put in place the 
appropriate handling.

5. AssetHost will return a 302 Found to the rendered image asset if it 
exists, or render it on-the-fly if it does not yet exist.

# Rich Media Support

Rich media assets are delivered as specially-tagged img tags, and are 
replaced on the client-side via an AssetHost.Client plugin.

### Brightcove Video

Brightcove videos can be imported as assets and used to place videos into 
image display contexts. The video is delivered as an img tag, and the 
AssetHost.Client library will see the tag and call the 
AssetHost.Client.Brightcove plugin. The plugin will place an overlay on top 
of the image with a class of BrightcoveVideoOverlay.  When clicked, the 
image will be replaced by a Brightcove player object.

Brightcove assets can be imported using the interface at /a/brightcove/

# Image Storage

AssetHost intends to support any image storage supported by 
[Paperclip](https://github.com/thoughtbot/paperclip), the underlying gem 
responsible for adding image file functionality to our Asset model.

Currently, Paperclip supports local filesystem storage and storage on 
Amazon's S3.

# External Requirements

### Async Workers via Redis

The AssetHost server uses Redis (via the Resque gem) to coordinate async 
processing of images.  Configure for your Redis setup in config/resque.yml.

### Image Processing via ImageMagick

AssetHost, via Paperclip, does image processing using ImageMagick.  If 
needed, make sure to specify Paperclip.options[:command_path] in your config.

### Text Search via Sphinx

Searches are done via Sphinx, using the Thinking Sphinx gem.  Set up your 
configuration in config/sphinx.yml, and make sure you have an external trigger
for indexing (cron, etc).

# Credits

AssetHost is being developed to serve the media asset needs of [KPCC](http://kpcc.org) 
and Southern California Public Radio, a member-supported public radio network that 
serves Los Angeles and Orange County on 89.3, the Inland Empire on 89.1, and the 
Coachella Valley on 90.3.

AssetHost development is led by Eric Richardson (erichardson@kpcc.org).
