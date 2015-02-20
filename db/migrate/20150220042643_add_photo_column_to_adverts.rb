class AddPhotoColumnToAdverts < ActiveRecord::Migration
  def change
    add_column :auto_adverts, :photo_url, :text
  end
end
