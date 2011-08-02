class AddTokenAuthToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.token_authenticatable
    end
  end
end
