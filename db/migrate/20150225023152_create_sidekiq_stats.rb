class CreateSidekiqStats < ActiveRecord::Migration
  def change
    create_table :sidekiq_stats do |t|
      t.integer :workers_size
      t.integer :enqueued

      t.timestamps null: false
    end
  end
end
