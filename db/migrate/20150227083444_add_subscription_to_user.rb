class AddSubscriptionToUser < ActiveRecord::Migration
  def change
    add_reference :users, :subscription, index: true
    add_foreign_key :users, :subscriptions
  end
end
