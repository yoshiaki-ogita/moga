# 二段の鍵の設定（守り2 ②）。使うかどうかは、利用者が選ぶ
#   show   … 今の様子（使っているか・残りの予備の鍵の数）
#   new    … QR コードを出し、スマホのアプリで読んでもらう
#   create … アプリの6桁を1回合わせたら使い始め、予備の鍵16個を一度だけ出す
class TwoFactorsController < ApplicationController
  # 6桁を総当たりで試されないよう、3分間に10回まで
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  LIMIT = 10
  WITHIN = 3.minutes

  before_action :require_login
  before_action :reject_demo
  before_action :redirect_if_enabled, only: %i[new create]
  rate_limit to: LIMIT, within: WITHIN, only: :create, store: RATE_LIMIT_STORE,
             with: -> { too_many_attempts }

  def show
  end

  def new
    # 読み直しても同じ QR コードが出るように、種がまだ無い時だけ作る
    current_user.prepare_otp! if current_user.otp_secret.blank?
  end

  def create
    unless current_user.enable_otp!(params[:code])
      flash.now[:alert] = "6桁の数字が合いません。アプリに今出ている数字を入れてください"
      return render :new, status: :unprocessable_content
    end

    @backup_codes = current_user.regenerate_backup_codes!
    # 予備の鍵が出た画面を、ブラウザに残さない（戻るボタンや履歴で他人に見られないように）
    response.headers["Cache-Control"] = "no-store"
    render :backup_codes
  end

  private

  def reject_demo
    return unless demo?

    redirect_to home_path, alert: "お試し中は見るだけです"
  end

  def redirect_if_enabled
    return unless current_user.otp_enabled?

    redirect_to two_factor_path, notice: "二段の鍵は、もう使っています"
  end

  def too_many_attempts
    flash.now[:alert] = "試みが多すぎます。しばらく待ってから、もう一度お試しください"
    render :new, status: :too_many_requests
  end
end
