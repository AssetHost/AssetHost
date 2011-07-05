class RemoveIdKey < ActiveRecord::Migration
  def up
    remove_column :assets, :idkey
  end

  def down
    change_table(:assets) do |t|
      t.string :idkey
    end
    
    Asset.all.each { |a| 
      a.idkey = a.id
      a.save
    }
  end
end
