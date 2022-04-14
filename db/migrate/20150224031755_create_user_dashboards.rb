class CreateUserDashboards < ActiveRecord::Migration
  def change
    create_table :user_dashboards do |t|
      t.belongs_to :user, index: true, unique: true
      t.integer :domains_crawled
      t.integer :domains_broken
      t.integer :domains_expired
      t.integer :pending_crawlers
      t.integer :running_crawlers

      t.timestamps null: false
    end
    add_foreign_key :user_dashboards, :users
  end
end
