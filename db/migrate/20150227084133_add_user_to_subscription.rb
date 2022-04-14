class AddUserToSubscription < ActiveRecord::Migration
  def up
    add_index :subscriptions, :user_id, unique: true
    add_foreign_key :subscriptions, :users
  end
  def down
    remove_index :subscriptions, :user_id
    remove_foreign_key :subscriptions, :users
  end
end
