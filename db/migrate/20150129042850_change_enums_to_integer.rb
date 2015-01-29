class ChangeEnumsToInteger < ActiveRecord::Migration
  def change
  	remove_column :auto_adverts, :fuel
    remove_column :auto_adverts, :body
    remove_column :auto_adverts, :steering_wheel
    remove_column :auto_adverts, :drive
    remove_column :auto_adverts, :transmission

    add_column :auto_adverts, :fuel, :integer
    add_column :auto_adverts, :body, :integer
    add_column :auto_adverts, :steering_wheel, :integer
    add_column :auto_adverts, :drive, :integer
    add_column :auto_adverts, :transmission, :integer
  end
end
