class CreateAvailableDomains < ActiveRecord::Migration
  def change
    create_table :available_domains do |t|
      t.integer :crawl_id
      t.text :anchor_texts, array:true, default: []

      t.timestamps null: false
    end
  end
end
