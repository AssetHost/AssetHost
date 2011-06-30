class AddDimensionsToAssetOutput < ActiveRecord::Migration
  def up
    change_table(:asset_outputs) do |t|
      t.integer :width, :height
    end
  end

  def down
    remove_column :asset_outputs, :width
    remove_column :asset_outputs, :height
  end
end
