class AddDbUrlPartsToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :db_user, :string
    add_column :heroku_apps, :db_pass, :string
    add_column :heroku_apps, :db_host, :string
    add_column :heroku_apps, :db_port, :integer
    add_column :heroku_apps, :db_name, :string
  end
end
