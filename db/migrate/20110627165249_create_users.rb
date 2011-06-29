class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.database_authenticatable :null => false
      t.rememberable
      t.trackable
      
      t.string :username, :null => false, :unique => true
      t.boolean :is_admin, :default => false, :null => false
      t.belongs_to :default_site, :null => false

      t.timestamps
    end
  end
end
