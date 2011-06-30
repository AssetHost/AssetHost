class RemoveImageProcessingFromAsset < ActiveRecord::Migration
  def up
    remove_column :assets, :image_processing
  end

  def down
    change_table(:assets) do |t|
      t.boolean :image_processing, :default => false
    end
  end
end
