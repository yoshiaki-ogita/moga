class CreatePhases < ActiveRecord::Migration[8.1]
  def change
    create_table :phases do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :phases, %i[user_id code], unique: true
  end
end
