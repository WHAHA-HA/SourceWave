class CreateDomainForSales < ActiveRecord::Migration
  def change
    create_table :domain_for_sales do |t|
      t.string :url
      t.integer :site_id
      t.float :citationflow
      t.float :trustflow
      t.float :trustmetric
      t.float :pa
      t.float :da
      t.integer :refdomains
      t.integer :backlinks
      t.integer :crawl_id
      t.string :processor_name
      t.integer :seller_id
      t.integer :buyer_id
      t.integer :views
      t.integer :wishlist_count
      t.float :price

      t.timestamps null: false
    end
  end
end
