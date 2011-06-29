class CreateKpccSizes < ActiveRecord::Migration
  def up
    p = SitePackage.create(:name => "KPCC.org",:url => "http://www.kpcc.org", :description => "Default sizes for KPCC.org")
    
    p.outputs.create(:code => "thumb", :size => "88x88#", :is_rich => false, :extension => "jpg", :prerender => true)
    p.outputs.create(:code => "lsquare", :size => "188x188#", :is_rich => false, :extension => "jpg", :prerender => true)
    p.outputs.create(:code => "lead", :size => "324x324>", :is_rich => false, :extension => "jpg", :prerender => false)
    p.outputs.create(:code => "wide", :size => "620x414>", :is_rich => true, :extension => "jpg", :prerender => true)
    p.outputs.create(:code => "full", :size => "1024x1024>", :is_rich => true, :extension => "jpg", :prerender => false)    
  end

  def down
  end
end
