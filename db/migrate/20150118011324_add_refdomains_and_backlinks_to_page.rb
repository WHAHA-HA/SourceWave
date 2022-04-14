class AddRefdomainsAndBacklinksToPage < ActiveRecord::Migration
  def change
    add_column :pages, :refdomains, :string
    add_column :pages, :backlinks, :string
  end
end
