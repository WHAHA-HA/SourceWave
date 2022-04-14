class AddRedirectThroughToPage < ActiveRecord::Migration
  def change
    add_column :pages, :redirect_through, :text
  end
end
