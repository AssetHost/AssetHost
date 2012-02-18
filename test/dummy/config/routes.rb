Rails.application.routes.draw do

  mount AssetHostCore::Engine => "/asset_host_core"
end
