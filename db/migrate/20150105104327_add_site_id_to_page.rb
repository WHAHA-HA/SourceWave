class AddSiteIdToPage < ActiveRecord::Migration
  def change
    add_column :pages, :site_id, :integer
  end
end
