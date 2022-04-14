class AddGuaranteedToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :guaranteed, :boolean
  end
end
