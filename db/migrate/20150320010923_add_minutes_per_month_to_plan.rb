class AddMinutesPerMonthToPlan < ActiveRecord::Migration
  def change
    add_column :plans, :minutes_per_month, :float
  end
end
