# 行動予定（轍の①）。例：5:00〜6:30／H3 継続受講／Railsの復習
class DiaryPlan < ApplicationRecord
  belongs_to :diary
  belongs_to :window

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :memo, length: { maximum: 50 }
  validate :ends_after_start
  validate :window_is_owners

  # 「5:00〜6:30」のような時間帯
  def time_label
    "#{starts_at.strftime('%-H:%M')}〜#{ends_at.strftime('%-H:%M')}"
  end

  private

  # 終わりは、始まりより後
  def ends_after_start
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "は始まりより後の時刻にしてください")
  end

  # 自分の小窓だけを選べる（他人の小窓は選べない）
  def window_is_owners
    return if window.blank? || diary.blank?
    return if window.phase.user_id == diary.user_id

    errors.add(:window, "は一覧にありません")
  end
end
