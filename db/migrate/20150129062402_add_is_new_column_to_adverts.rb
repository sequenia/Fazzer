class AddIsNewColumnToAdverts < ActiveRecord::Migration
  def change
    add_column :auto_adverts, :is_new, :boolean, :default => true
  end
end
