class PhasesController < ApplicationController
  before_action :require_login

  def show
    # 自分の大窓だけを探す（他人の大窓の番号を打っても見つからない）
    @phase = current_user.phases.find(params[:id])
  end
end
