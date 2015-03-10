class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.integer :adverts_per_process
      t.integer :adverts_per_thread

      t.timestamps null: false
    end

    Setting.create({adverts_per_process: 100, adverts_per_thread: 5})
  end
end
