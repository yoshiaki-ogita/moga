# 達成率型の小窓に「全体の数」を足す（#128）
#   例：社労士の過去問が 700問 なら 700
#   空欄でもよい（空欄の小窓は、今までどおり「できた ÷ やった」で数える）
class AddTargetCountToWindows < ActiveRecord::Migration[8.1]
  def change
    add_column :windows, :target_count, :integer
  end
end
