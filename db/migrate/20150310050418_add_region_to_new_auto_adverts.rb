class AddRegionToNewAutoAdverts < ActiveRecord::Migration
  def change
  	add_column :new_auto_adverts, :region_href, :text
  end
end
