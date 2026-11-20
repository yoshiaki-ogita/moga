# 轍の①「実際は？」を、時刻を書かずに1回押すだけにする（#123）
#   outcome：kept（◎ 予定どおり）／shifted（○ 少しずれた）／missed（△ できなかった）
#   今までの「予定どおり✓」は kept に、「ずれた時の時刻」を書いた行は shifted に引き継ぐ
#   as_planned・actual_starts_at・actual_ends_at の列と中身は消さずに残す
class AddOutcomeToDiaryPlans < ActiveRecord::Migration[8.1]
  def up
    add_column :diary_plans, :outcome, :string, limit: 10
    execute "UPDATE diary_plans SET outcome = 'kept' WHERE as_planned = TRUE"
    execute <<~SQL
      UPDATE diary_plans SET outcome = 'shifted'
      WHERE as_planned = FALSE AND actual_starts_at IS NOT NULL AND actual_ends_at IS NOT NULL
    SQL
  end

  def down
    remove_column :diary_plans, :outcome
  end
end
