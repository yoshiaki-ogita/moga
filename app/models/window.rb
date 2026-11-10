# 小窓（窓 1〜8）。1つの大窓に最大8つ
class Window < ApplicationRecord
  NUMBERS = (1..8).to_a.freeze

  belongs_to :phase
  # 小窓を消すと、中の課題も一緒に消える（11/7 決裁）
  has_many :plans, -> { order(:created_at) }, dependent: :destroy

  # 数え方：課題型（課題の「済み ÷ 課題」）／達成率型（記録の「できた ÷ やった」）
  enum :measure, { plan_count: 0, achievement_rate: 1 }, validate: true

  validates :number, presence: true, inclusion: { in: NUMBERS }, uniqueness: { scope: :phase_id }
  validates :title, presence: true, length: { maximum: 30 }
end
