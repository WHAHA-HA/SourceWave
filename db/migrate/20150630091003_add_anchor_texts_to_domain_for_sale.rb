class AddAnchorTextsToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :anchor_texts, :text, array:true, default: []
  end
end
