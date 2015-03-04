class CreateParsingResults < ActiveRecord::Migration
  def change
    create_table :parsing_results do |t|
      t.integer :region_id
      t.integer :new_adverts_count, default: 0
      t.boolean :success, default: false

      t.timestamps null: false
    end
  end
end
