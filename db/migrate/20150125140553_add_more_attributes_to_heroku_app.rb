class AddMoreAttributesToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :started_at, :datetime
    add_column :heroku_apps, :finished_at, :datetime
    add_column :heroku_apps, :batch_id, :string
  end
end
