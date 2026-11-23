# ログインの2段目（守り2 ③）
#   パスワードが通った人にだけ、アプリの6桁（または予備の鍵）を聞く。
#   たとえ：玄関の鍵（パスワード）を開けた人に、内側のダイヤル錠の番号を聞く。
#           両方そろって、初めて家に入れる。
class TwoFactorLoginsController < ApplicationController
  # パスワードが通ってから、6桁を入れるまでの持ち時間
  PENDING_WITHIN = 5.minutes

  # 6桁を総当たりで試されないよう、同じ人には15分間に10回まで
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  LIMIT = 10
  WITHIN = 15.minutes

  before_action :require_pending_user
  rate_limit to: LIMIT, within: WITHIN, only: :create, store: RATE_LIMIT_STORE,
             by: -> { session[:otp_user_id].to_s.presence || request.remote_ip },
             with: -> { too_many_attempts }

  def new
  end

  def create
    used = @pending_user.verify_otp_or_backup_code(params[:code])
    unless used
      flash.now[:alert] = "数字か予備の鍵が合いません。アプリに今出ている6桁を入れてください"
      return render :new, status: :unprocessable_content
    end

    log_in(@pending_user)
    redirect_to home_path, notice: login_notice(used)
  end

  private

  # パスワードが通った人で、持ち時間の内にいるか
  def require_pending_user
    started_at = session[:otp_started_at].to_i
    @pending_user = User.find_by(id: session[:otp_user_id]) if started_at > PENDING_WITHIN.ago.to_i
    return if @pending_user&.otp_enabled?

    session.delete(:otp_user_id)
    session.delete(:otp_started_at)
    redirect_to login_path, alert: "もう一度、メールアドレスとパスワードからログインしてください"
  end

  def login_notice(used)
    return "ログインしました" if used == :otp

    "ログインしました。予備の鍵を1つ使いました（残り#{@pending_user.remaining_backup_codes_count}個）"
  end

  def too_many_attempts
    flash.now[:alert] = "試みが多すぎます。しばらく待ってから、もう一度お試しください"
    render :new, status: :too_many_requests
  end
end
