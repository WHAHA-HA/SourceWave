class AddPlanNameToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :plan_name, :string
  end
end
