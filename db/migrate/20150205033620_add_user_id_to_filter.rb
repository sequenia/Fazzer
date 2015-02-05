class AddUserIdToFilter < ActiveRecord::Migration
  def change
    add_column :auto_filters, :user_id, :integer
  end
end
