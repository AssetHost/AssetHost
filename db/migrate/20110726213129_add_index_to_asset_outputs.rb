class AddIndexToAssetOutputs < ActiveRecord::Migration
  def change
    add_index :asset_outputs, [:asset_id,:output_id], :unique => true
  end
end
