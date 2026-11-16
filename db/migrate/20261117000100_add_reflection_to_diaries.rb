# ⑤ 今日もう一度やり直せるとしたら？（5行まで。3つ以上を目指す）
# ⑥ 今日自分の自信を育てた出来事3つ（嬉しかったこと・成長したこと・ありがとう）
class AddReflectionToDiaries < ActiveRecord::Migration[8.1]
  def change
    (1..5).each { |n| add_column :diaries, :"redo_#{n}", :string }
    add_column :diaries, :joy, :string
    add_column :diaries, :growth, :string
    add_column :diaries, :thanks, :string
  end
end
