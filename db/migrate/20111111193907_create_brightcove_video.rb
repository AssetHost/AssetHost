class CreateBrightcoveVideo < ActiveRecord::Migration
  def change
    create_table :brightcove_videos do |t|
      t.integer :videoid, :limit => 8, :null => false
      t.integer :length
      t.timestamps
    end
  end
end
