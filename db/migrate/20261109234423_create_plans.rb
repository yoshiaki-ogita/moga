class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :window, null: false, foreign_key: true
      t.string :title, null: false
      # 済んだ日時（空＝まだ、入っている＝済み）。講師の助言で done ではなく done_at
      t.datetime :done_at

      t.timestamps
    end
  end
end
