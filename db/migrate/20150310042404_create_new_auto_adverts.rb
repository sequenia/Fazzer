class CreateNewAutoAdverts < ActiveRecord::Migration
  def change
    create_table :new_auto_adverts do |t|
      t.text :url
      t.string :code
      t.text :photo_preview_url

      t.timestamps null: false
    end
  end
end
