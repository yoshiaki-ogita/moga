class CreateWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :windows do |t|
      t.references :phase, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :title, null: false
      t.integer :measure, null: false, default: 0

      t.timestamps
    end
    add_index :windows, %i[phase_id number], unique: true
  end
end
