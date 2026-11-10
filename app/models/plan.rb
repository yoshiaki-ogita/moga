# 課題。課題型の小窓で「済み ÷ 課題」を数えるもと
class Plan < ApplicationRecord
  belongs_to :window

  validates :title, presence: true, length: { maximum: 50 }

  # done_at が空＝まだ、入っている＝済み
  scope :undone, -> { where(done_at: nil) }
  scope :done, -> { where.not(done_at: nil) }

  # 「済み」にする（#23）。済んだ日時に今の時刻を入れる（#35 Controller から移した）
  def done!
    update!(done_at: Time.current)
  end

  # 「まだ」に戻す（#23）
  def undone!
    update!(done_at: nil)
  end

  def done?
    done_at.present?
  end
end
