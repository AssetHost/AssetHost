class AddHiddenToAssets < ActiveRecord::Migration
  def change
    change_table :assets do |t|
      t.boolean :is_hidden, :null => false, :default => false
    end
  end
end
