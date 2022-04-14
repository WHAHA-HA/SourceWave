class CreateExpiredLinks < ActiveRecord::Migration
  def change
    create_table :expired_links do |t|
      t.string :url
      t.string :available
      t.text :site_i
      t.integer :site_id
      t.boolean :internal
      t.text :found_on
      t.text :simple_url
      t.string :available
      t.string :citationflow
      t.string :trustflow
      t.string :trustmetric
      t.string :refdomains
      t.string :backlinks
      t.string :pa
      t.string :da

      t.timestamps null: false
    end
  end
end
