class AddFingerprintToAssetOutput < ActiveRecord::Migration
  def change
    change_table :asset_outputs do |t|
      t.string :image_fingerprint, :null => false, :default => ''
    end
    
    # add fingerprint to existing outputs
    AssetOutput.all.each do |ao|
      ao.image_fingerprint = ao.asset.image_fingerprint
      ao.save
    end
  end
end
