class CreateAssetOutputs < ActiveRecord::Migration
  def change
    create_table :asset_outputs do |t|
      t.belongs_to :asset, :null => false
      t.belongs_to :output, :null => false
      t.string :fingerprint
      t.timestamps
    end
  end
end
