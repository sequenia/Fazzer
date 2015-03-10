class RegenerateColumnsInParsingResults < ActiveRecord::Migration
  def change
    add_column :parsing_results, :info, :text

    ParsingResult.all.each do |parsing_result|
      parsing_result.update_attributes({
      	info: "Region #{parsing_result.region_id} parsed"
      })
    end

    remove_column :parsing_results, :region_id, :integer
    remove_column :parsing_results, :new_adverts_count, :integer
  end
end
