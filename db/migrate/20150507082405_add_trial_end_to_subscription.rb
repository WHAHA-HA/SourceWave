class AddTrialEndToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :trial_end, :string
  end
end
