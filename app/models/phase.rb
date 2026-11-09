# 大窓（局面）。1人の利用者に A〜H の8つ
class Phase < ApplicationRecord
  CODES = %w[A B C D E F G H].freeze

  belongs_to :user

  validates :code, presence: true, inclusion: { in: CODES }, uniqueness: { scope: :user_id }
  validates :name, presence: true, length: { maximum: 30 }
end
