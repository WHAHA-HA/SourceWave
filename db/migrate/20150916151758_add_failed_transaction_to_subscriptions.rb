class AddFailedTransactionToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :failed_transaction, :boolean, default: false
  end
end
