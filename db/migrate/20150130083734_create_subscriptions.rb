class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :user_id
      t.string :stripe_customer_token
      t.string :status
      t.integer :plan_id

      t.timestamps null: false
    end
  end
end
