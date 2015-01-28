class CreateCarModels < ActiveRecord::Migration
  def change
    create_table :car_models do |t|
      t.string :name
      t.integer :car_mark_id

      t.timestamps null: false
    end
  end
end
