class AddSuffixToDomainForSale < ActiveRecord::Migration
  def change
    add_column :domain_for_sales, :suffix, :string
  end
end
