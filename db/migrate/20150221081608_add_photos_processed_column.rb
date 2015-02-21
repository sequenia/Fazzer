class AddPhotosProcessedColumn < ActiveRecord::Migration
  def change
    add_column :auto_adverts, :photos_processed, :boolean, default: false
  end
end
