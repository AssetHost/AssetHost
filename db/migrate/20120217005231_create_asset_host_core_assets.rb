class CreateAssetHostCoreAssets < ActiveRecord::Migration
  def change
    create_table :asset_host_core_assets do |t|
      t.string :title, :owner, :url
      t.text :caption, :notes
      t.belongs_to :creator, :null => true
      
      t.string :image_file_name, :image_content_type, :image_copyright, :image_fingerprint, :image_title, :image_description
      t.string :image_gravity
      
      t.integer :image_width, :image_height, :image_file_size, :image_version
      t.datetime :image_updated_at, :image_taken
      
      t.belongs_to :native, :polymorphic => true
      
      t.boolean :is_hidden, :default => false, :null => false

      t.timestamps
    end
  end
end
