class AddPhotoPreviewUrlColumnToAdverts < ActiveRecord::Migration
  def change
    add_column :auto_adverts, :photo_preview_url, :text
  end
end
