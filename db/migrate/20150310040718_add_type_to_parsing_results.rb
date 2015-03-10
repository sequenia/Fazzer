class AddTypeToParsingResults < ActiveRecord::Migration
  def change
    add_column :parsing_results, :result_type, :integer, default: 0
  end
end
