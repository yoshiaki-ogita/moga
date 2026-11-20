# △ できなかった予定を、明日の轍へ写す（#123）
#   「反省」で終わらせず、1回押すだけで明日の一歩につなげる
class DiaryPlansController < ApplicationController
  before_action :require_login

  def carry
    plan = DiaryPlan.joins(:diary).where(diaries: { user_id: current_user.id }).find(params[:id])
    tomorrow = plan.carry_to_next_day
    label = "「#{plan.time_label} #{plan.window_code}」"
    notice = tomorrow ? "#{label}を#{tomorrow.date_label}の轍に回しました" : "#{label}は、もう明日の轍にあります"
    redirect_to diary_path(plan.diary.diary_on), notice: notice
  end
end
