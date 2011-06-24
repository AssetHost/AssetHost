class CreateAssets < ActiveRecord::Migration
  def change    
    create_table :assets do |t|
      t.string :idkey, :unique => true, :null => false
      t.string :title, :description, :owner, :url
      t.belongs_to :creator, :null => false, :default => 1
      t.text :notes
            
      t.string :image_file_name, :image_content_type, :image_copyright, :image_fingerprint
      t.datetime :image_updated_at
      t.boolean :image_processing, :default => false
      t.string :image_gravity, :null => false, :default => "center"
      t.integer :image_width, :image_height, :image_file_size, :image_version
      t.datetime :image_taken
      
      t.belongs_to :native, :polymorphic => true
      
      t.timestamps
    end
  end
end
