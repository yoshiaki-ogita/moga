# わたしの轍（1日に1つの日誌）。前の日の夜に書く「今日の一言」「今日必ずやること」を持つ
class CreateDiaries < ActiveRecord::Migration[8.1]
  def change
    create_table :diaries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :diary_on, null: false
      t.string :word
      t.text :must_do
      t.timestamps
    end
    # 1人の利用者に、1日1つだけ
    add_index :diaries, [ :user_id, :diary_on ], unique: true
  end
end
