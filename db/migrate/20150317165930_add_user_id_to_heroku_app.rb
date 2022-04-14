class AddUserIdToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :user_id, :integer
  end
end
