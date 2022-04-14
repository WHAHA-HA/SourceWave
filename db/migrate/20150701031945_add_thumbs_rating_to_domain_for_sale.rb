class AddThumbsRatingToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :thumbs_up_count, :integer
    add_column :domain_for_sales, :thumbs_down_count, :integer
  end
end
