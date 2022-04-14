class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.string :base_url
      t.integer :crawl_id

      t.timestamps
    end
  end
end
