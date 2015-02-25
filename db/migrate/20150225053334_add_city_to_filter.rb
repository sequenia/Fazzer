class AddCityToFilter < ActiveRecord::Migration
  def change
    add_column :auto_filters, :city_id, :integer
  end
end
