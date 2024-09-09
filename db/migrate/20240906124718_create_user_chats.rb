class CreateUserChats < ActiveRecord::Migration[7.2]
  def change
    create_table :user_chats do |t|
      t.string :user_id
      t.text :promot
      t.string :type

      t.timestamps
    end
  end
end
