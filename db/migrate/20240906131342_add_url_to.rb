class AddUrlTo < ActiveRecord::Migration[7.2]
  def change
    add_column :user_chats, :url, :string
  end
end
