# 轍の④「今日1日の自分の行動の評価」。その日の終わりに、5つの項目へ a〜e とコメントを書く
class AddReviewToDiaries < ActiveRecord::Migration[8.1]
  def change
    %i[mind skill body life overall].each do |item|
      add_column :diaries, :"#{item}_grade", :string, limit: 1
      add_column :diaries, :"#{item}_comment", :string
    end
  end
end
