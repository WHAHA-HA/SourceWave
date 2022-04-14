class AddUrlToAvailableDomains < ActiveRecord::Migration
  def change
    add_column :available_domains, :url, :string
  end
end
