class CreateUserPrompts < ActiveRecord::Migration[7.2]
  def change
    create_table :user_prompts do |t|
      t.string :user_id
      t.string :doc_url

      t.timestamps
    end
  end
end
