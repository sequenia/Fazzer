class CreateCarMarks < ActiveRecord::Migration
  def change
    create_table :car_marks do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
