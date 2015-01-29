class AddLinkToAutoAdverts < ActiveRecord::Migration
  def change
    add_column :auto_adverts, :url, :text
  end
end
