# 大窓に「なぜ そこへ向かうのか」の自由記載メモを1つ持たせる（#145）
class AddMemoToPhases < ActiveRecord::Migration[8.1]
  def change
    add_column :phases, :memo, :text
  end
end
