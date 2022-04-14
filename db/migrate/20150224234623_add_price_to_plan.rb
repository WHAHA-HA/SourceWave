class AddPriceToPlan < ActiveRecord::Migration
  def change
    add_column :plans, :price, :float
  end
end
