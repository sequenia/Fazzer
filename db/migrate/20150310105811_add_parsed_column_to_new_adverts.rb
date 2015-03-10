class AddParsedColumnToNewAdverts < ActiveRecord::Migration
  def change
  	add_column :new_auto_adverts, :parsed, :boolean, default: false
  end
end
