class ChangeDescriptionToCaption < ActiveRecord::Migration
  def change
    rename_column :assets, :description, :caption
  end
end
