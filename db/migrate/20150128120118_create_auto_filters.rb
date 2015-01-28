class CreateAutoFilters < ActiveRecord::Migration
  def change
    create_table :auto_filters do |t|
      t.integer :car_mark_id
      t.integer :car_model_id
      t.integer :min_year
      t.integer :max_year
      t.float :min_price
      t.float :max_price

      t.timestamps null: false
    end
  end
end
