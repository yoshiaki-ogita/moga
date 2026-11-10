# 記録（#24）。達成率型の小窓に、毎日「やった数」と「できた数」を書く
# 例：社労士の労基法を20問解いて（やった数）16問正解（できた数）
class Entry < ApplicationRecord
  belongs_to :window

  validates :recorded_on, presence: true
  validates :attempted_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :achieved_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :title, length: { maximum: 50 }
  validates :body, length: { maximum: 1000 }
  validate :achieved_not_more_than_attempted

  # 「11月10日」のような短い日付（お知らせの文に使う。#35 Controller から移した）
  def date_label
    recorded_on.strftime("%-m月%-d日")
  end

  private

  # できた数は、やった数より多くならない（20問中21問正解はありえない）
  def achieved_not_more_than_attempted
    return if attempted_count.blank? || achieved_count.blank?
    return if achieved_count <= attempted_count

    errors.add(:achieved_count, "はやった数以下にしてください")
  end
end
