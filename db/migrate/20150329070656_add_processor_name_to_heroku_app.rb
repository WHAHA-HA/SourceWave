class AddProcessorNameToHerokuApp < ActiveRecord::Migration
  def change
    add_column :heroku_apps, :processor_name, :string
  end
end
