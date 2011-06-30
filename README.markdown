# AssetHost

AssetHost is an attempt to create a one-stop-shop for hosting and linking 
to media assets that are intended for inclusion in news stories.  The goal is 
to create a hub that multiple frontend CMS systems can hook into, querying 
images, videos and documents from one source and enabling the easier 
interchange of data.

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

AssetHost development is led by Eric Richardson (<erichardson@kpcc.org>).
