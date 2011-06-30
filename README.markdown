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

### Backend Server

The backend server provides the primary UI for uploading, managing, and  
serving assets. It is built in Ruby on Rails.

### Frontend Plugins

The plugins should allow a UI for choosing assets to attach to the CMS, 
and should handle calling the backend server to get the HTML code for a 
given asset context.

### Workflow

1. Photographer / Author / Editor goes to AssetHost and uploads or imports 
a media asset.

2. Author / Editor goes to their frontend CMS and uses the plugin UI to 
select the asset they want to attach to their content (which might be a 
story, a blog post, etc).

3. CMS plugin uses API to query AssetHost and retrieve presentation code 
for the asset.  This could be an image tag, HTML to embed a video, etc. 
This code is integrated with CMS output and rendered to a web user (and 
can be cached to render to many web users).

4. If the presentation code includes an image asset, the web user's browser 
will attempt to load that image from AssetHost.

5. AssetHost will return a 302 Found to the rendered image asset if it 
exists, or render it on-the-fly if it does not yet exist.

# Image Storage

AssetHost intends to support any image storage supported by 
[Paperclip](https://github.com/thoughtbot/paperclip), the underlying gem 
responsible for adding image file functionality to our Asset model.

Currently, Paperclip supports local filesystem storage and storage on 
Amazon's S3.

# External Requirements

### Async Processing via Redis

The AssetHost server uses Redis (via the Resque gem) to coordinate async 
processing of images.

# Credits

AssetHost is being developed to serve the media asset needs of [KPCC](http://kpcc.org) 
and Southern California Public Radio, a member-supported public radio network that 
serves Los Angeles and Orange County on 89.3, the Inland Empire on 89.1, and the 
Coachella Valley on 90.3.

AssetHost development is led by Eric Richardson (erichardson@kpcc.org).
