class AddRegionIdToParsingResults < ActiveRecord::Migration
  def change
    add_column :parsing_results, :region_id, :integer
  end
end
