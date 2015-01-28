class AddModelAndMarkToAvert < ActiveRecord::Migration
  def change
    remove_column :auto_adverts, :model_id
    add_column :auto_adverts, :car_model_id, :integer
    add_column :auto_adverts, :car_mark_id, :integer
  end
end
