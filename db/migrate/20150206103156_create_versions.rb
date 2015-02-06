class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.integer :car_models, default: 1
      t.integer :car_marks, default: 1
      t.integer :cities, default: 1

      t.timestamps null: false
    end
  end
end
