class AddVerifiedToPages < ActiveRecord::Migration
  def change
    add_column :pages, :verified, :boolean
  end
end
