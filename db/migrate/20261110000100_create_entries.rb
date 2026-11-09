class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.references :window, null: false, foreign_key: true
      t.date :recorded_on, null: false
      t.integer :attempted_count, null: false, default: 0
      t.integer :achieved_count, null: false, default: 0
      t.string :title
      t.text :body

      t.timestamps
    end
    add_index :entries, [ :window_id, :recorded_on ]
  end
end
