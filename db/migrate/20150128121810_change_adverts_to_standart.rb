class ChangeAdvertsToStandart < ActiveRecord::Migration
  def change
    remove_column :auto_adverts, :engine
    add_column :auto_adverts, :displacement, :float
    add_column :auto_adverts, :fuel, :string
  end
end
