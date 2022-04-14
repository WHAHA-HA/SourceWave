class AddSellerPaypalEmailToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :seller_paypal_email, :string
  end
end
