# 大窓（局面）。1人の利用者に A〜H の8つ
class Phase < ApplicationRecord
  CODES = %w[A B C D E F G H].freeze

  belongs_to :user
  has_many :windows, -> { order(:number) }, dependent: :destroy

  validates :code, presence: true, inclusion: { in: CODES }, uniqueness: { scope: :user_id }
  validates :name, presence: true, length: { maximum: 30 }

  # 大窓の進捗率（#28）＝中の小窓の進捗率の平均。小窓が1つもなければ 0
  def progress_rate
    return 0.0 if windows.empty?

    windows.sum(&:progress_rate) / windows.size
  end

  def progress_percent
    (progress_rate * 100).round
  end

  # まだ使っていない小窓の番号（1〜8）
  def free_window_numbers
    Window::NUMBERS - windows.pluck(:number)
  end
end
