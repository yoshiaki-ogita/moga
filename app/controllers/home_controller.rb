class HomeController < ApplicationController
  before_action :require_login

  # 3×3 のマスに並べる順番（真ん中が本人。A から時計回り）
  #   A B C
  #   H ◯ D
  #   G F E
  MANDALA_ORDER = [ "A", "B", "C", "H", :me, "D", "G", "F", "E" ].freeze

  def index
    # 計算や読み込みはモデルに任せ、受け取って画面に渡すだけ（#35）
    @phases = current_user.mandala_phases
  end
end
