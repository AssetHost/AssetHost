class ChangeDescriptionToText < ActiveRecord::Migration
  def change
    change_column :assets, :description, :text
  end
end
