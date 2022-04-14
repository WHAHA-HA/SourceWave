class AddBasicLinkscapeApiToPage < ActiveRecord::Migration
  def change
    add_column :pages, :pa, :string
    add_column :pages, :da, :string
  end
end
