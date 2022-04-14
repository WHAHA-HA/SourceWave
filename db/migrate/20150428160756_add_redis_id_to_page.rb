class AddRedisIdToPage < ActiveRecord::Migration
  def change
    add_column :pages, :redis_id, :string
  end
end
