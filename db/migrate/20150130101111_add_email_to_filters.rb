class AddEmailToFilters < ActiveRecord::Migration
  def change
    add_column :auto_filters, :email, :string
  end
end
