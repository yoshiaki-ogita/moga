# 轍の①に「実際はどうだった？」を足す（寝る前に確かめる）
#   as_planned：予定どおりなら true（時刻は書かなくてよい）
#   actual_starts_at / actual_ends_at：ずれた時だけ、実際の時刻
class AddActualToDiaryPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :diary_plans, :as_planned, :boolean, null: false, default: false
    add_column :diary_plans, :actual_starts_at, :time
    add_column :diary_plans, :actual_ends_at, :time
  end
end
