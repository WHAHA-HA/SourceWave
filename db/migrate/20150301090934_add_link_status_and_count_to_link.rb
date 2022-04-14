class AddLinkStatusAndCountToLink < ActiveRecord::Migration
  def change
    add_column :links, :status, :string
    add_column :links, :links_count, :integer
  end
end
