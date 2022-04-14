class RemoveRedirectThroughFromPage < ActiveRecord::Migration
  def change
    remove_column :pages, :redirect_through, :string
  end
end
