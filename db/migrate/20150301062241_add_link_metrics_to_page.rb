class AddLinkMetricsToPage < ActiveRecord::Migration
  def change
    add_column :pages, :refdomains, :integer
    add_column :pages, :backlinks, :integer
  end
end
