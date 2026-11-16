# 行動予定（轍の①）。例：5:00〜6:30／H3 継続受講／Railsの復習
# 寝る前に「実際」を確かめる：予定どおりなら as_planned、ずれた時は実際の時刻
class DiaryPlan < ApplicationRecord
  belongs_to :diary
  belongs_to :window

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :memo, length: { maximum: 50 }
  validate :ends_after_start
  validate :actual_times_pair
  validate :window_is_owners

  # 「5:00〜6:30」のような時間帯
  def time_label
    "#{starts_at.strftime('%-H:%M')}〜#{ends_at.strftime('%-H:%M')}"
  end

  # 「H3」のような小窓の記号（円グラフの輪の上に書く）
  def window_code
    "#{window.phase.code}#{window.number}"
  end

  # 大窓の記号（A〜H）。円グラフの色を決める
  def phase_code
    window.phase.code
  end

  # 実際の時間帯 [始まり, 終わり]。まだ確かめていなければ nil
  def actual_range
    return [ starts_at, ends_at ] if as_planned?
    return [ actual_starts_at, actual_ends_at ] if actual_starts_at.present? && actual_ends_at.present?

    nil
  end

  def actual?
    actual_range.present?
  end

  private

  # 実際の時刻は、始まりと終わりをそろえて書く（予定どおりに✓なら要らない）
  def actual_times_pair
    return if as_planned?
    return if actual_starts_at.blank? && actual_ends_at.blank?

    if actual_starts_at.blank? || actual_ends_at.blank?
      errors.add(:base, "実際の時刻は、始まりと終わりの両方を書いてください")
    elsif actual_ends_at <= actual_starts_at
      errors.add(:actual_ends_at, "は実際の始まりより後の時刻にしてください")
    end
  end

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
