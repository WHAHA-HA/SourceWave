class AddBookmarkedToPage < ActiveRecord::Migration
  def change
    add_column :pages, :bookmarked, :boolean
  end
end
