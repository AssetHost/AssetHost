class CreateApiUsers < ActiveRecord::Migration
  def change
    create_table :api_users do |t|
      t.string "name", :null => false
      t.token_authenticatable
      t.timestamps
    end
  end
end
