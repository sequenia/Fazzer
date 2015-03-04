class AddIsParsingColumnToParsingResults < ActiveRecord::Migration
  def change
    add_column :parsing_results, :is_parsing, :boolean, default: true
  end
end
