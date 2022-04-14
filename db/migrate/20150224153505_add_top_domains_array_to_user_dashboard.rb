class AddTopDomainsArrayToUserDashboard < ActiveRecord::Migration
  def change
    add_column :user_dashboards, :top_domains, :text, array:true, default: []
  end
end
