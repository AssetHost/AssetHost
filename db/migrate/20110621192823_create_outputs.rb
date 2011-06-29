class CreateOutputs < ActiveRecord::Migration
  def change
    create_table :outputs do |t|
      t.belongs_to :site_package, :null => false
      t.string :code, :null => false, :unique => true
      t.string :size, :extension, :null => false
      t.boolean :is_rich, :default => true
      t.boolean :prerender, :default => false
      t.timestamps
    end
  end
end
