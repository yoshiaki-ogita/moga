class HomeController < ApplicationController
  before_action :require_login

  # 3×3 のマスに並べる順番（真ん中が本人。A から時計回り）
  #   A B C
  #   H ◯ D
  #   G F E
  MANDALA_ORDER = [ "A", "B", "C", "H", :me, "D", "G", "F", "E" ].freeze

  def index
    # #12 より前に登録した人にも、足りない大窓を用意する
    current_user.ensure_default_phases
    @phases = current_user.phases.index_by(&:code)
  end
end
