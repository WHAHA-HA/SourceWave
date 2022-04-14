class AddCancelDateToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :cancel_date, :datetime
  end
end
