class CreateAssetHostCoreAssetOutputs < ActiveRecord::Migration
  def change
    create_table :asset_host_core_asset_outputs do |t|
      t.belongs_to :asset, :null => false
      t.belongs_to :output, :null => false
      t.string :fingerprint
      t.string :image_fingerprint, :null => false
      t.integer :width, :height
      t.timestamps
    end
  end
end
