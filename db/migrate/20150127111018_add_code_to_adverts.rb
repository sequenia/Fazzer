class AddCodeToAdverts < ActiveRecord::Migration
  def change
    add_column :auto_adverts, :code, :string
  end
end
