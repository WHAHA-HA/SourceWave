class AddRatingToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :user_rating, :float
  end
end
