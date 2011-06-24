class CreateSitePackages < ActiveRecord::Migration
  def change
    create_table :site_packages do |t|
      t.string :name, :null => false, :unique => true
      t.string :url, :description
      t.timestamps
    end
  end
end
