class AddPageIdToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :page_id, :integer
  end
end
