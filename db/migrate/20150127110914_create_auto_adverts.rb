class CreateAutoAdverts < ActiveRecord::Migration
  def change
    create_table :auto_adverts do |t|
      t.datetime :date
      t.integer :model_id
      t.integer :year
      t.float :price
      t.string :phone
      t.string :engine
      t.string :transmission
      t.string :drive
      t.string :mileage
      t.string :steering_wheel
      t.text :description
      t.integer :city_id
      t.string :exchange
      t.string :color
      t.string :body

      t.timestamps null: false
    end
  end
end
