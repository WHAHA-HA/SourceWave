class AddSoldToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :sold, :boolean
  end
end
