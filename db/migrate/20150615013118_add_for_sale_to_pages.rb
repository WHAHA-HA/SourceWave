class AddForSaleToPages < ActiveRecord::Migration
  def change
    add_column :pages, :for_sale, :boolean, default: false
  end
end
