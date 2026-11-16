# 行動予定（轍の①）。時間帯ごとに、どの小窓に取り組むか
class CreateDiaryPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :diary_plans do |t|
      t.references :diary, null: false, foreign_key: true
      t.references :window, null: false, foreign_key: true
      t.time :starts_at, null: false
      t.time :ends_at, null: false
      t.string :memo
      t.timestamps
    end
  end
end
