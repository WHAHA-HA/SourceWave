class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :pages_per_crawl
      t.integer :expired_domains
      t.integer :broken_domains
      t.integer :crawls_at_the_same_time
      t.integer :reserve_period
      t.integer :crawl_speed
      t.boolean :marketplace

      t.timestamps null: false
    end
  end
end
