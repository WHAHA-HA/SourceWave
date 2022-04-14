class AddDefaultsToUserDashboard < ActiveRecord::Migration
  def up
    change_table :user_dashboards do |t|
      t.change_default :domains_crawled, 0
      t.change_default :domains_broken, 0
      t.change_default :domains_expired, 0
      t.change_default :pending_crawlers, 0
      t.change_default :running_crawlers, 0
      t.change_default :done_crawlers, 0
    end
  end
  def down
    change_table :user_dashboards do |t|
      t.change_default :domains_crawled, :null
      t.change_default :domains_broken, :null
      t.change_default :domains_expired, :null
      t.change_default :pending_crawlers, :null
      t.change_default :running_crawlers, :null
      t.change_default :done_crawlers, :null
    end
  end
end
