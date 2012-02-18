class CreateAssetHostCoreBrightcoveVideos < ActiveRecord::Migration
  def change
    create_table :asset_host_core_brightcove_videos do |t|
      t.integer :videoid, :null => false
      t.integer :length
      t.timestamps
    end
  end
end
