class AddSellerNotesToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :seller_notes, :string
  end
end
