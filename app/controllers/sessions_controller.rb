class SessionsController < ApplicationController
  # ログインの回数制限（#110）：同じ相手（IP アドレス）からは、3分間に10回まで。
  # パスワードを総当たりで試されるのを、入口で止める（多層防御）。
  # 数えた回数は、この画面専用の記憶の箱に置く（テストでも同じ動きを確かめられるように）
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  LOGIN_LIMIT = 10
  LOGIN_WITHIN = 3.minutes

  rate_limit to: LOGIN_LIMIT, within: LOGIN_WITHIN, only: :create, store: RATE_LIMIT_STORE,
             with: -> { too_many_attempts }

  # 2人目の番人（守り4、2026-11-23）：同じメールアドレスには、どこから来ても15分間に10回まで。
  # 悪い人がたくさんの機械を使い分け、少しずつ同じ人のパスワードを試すのを止める。
  # 回数と時間は作者が決めた（15分に10回）。ふだんのログインは1回なので、何も変わらない
  EMAIL_LIMIT = 10
  EMAIL_WITHIN = 15.minutes

  rate_limit to: EMAIL_LIMIT, within: EMAIL_WITHIN, only: :create, store: RATE_LIMIT_STORE, name: "email",
             by: -> { params[:email].to_s.strip.downcase.presence || request.remote_ip },
             with: -> { too_many_attempts }

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    return login_failed unless user&.authenticate(params[:password])
    return start_two_factor(user) if user.otp_enabled?

    log_in(user)
    redirect_to home_path, notice: "ログインしました"
  end

  def destroy
    log_out
    redirect_to root_path, notice: "ログアウトしました", status: :see_other
  end

  private

  # どちらが違うかは教えない（他人のメールアドレスを探られないため）
  def login_failed
    flash.now[:alert] = "メールアドレスかパスワードが正しくありません"
    render :new, status: :unprocessable_content
  end

  # 二段の鍵を使っている人（守り2 ③）：パスワードが合っても、まだ中には入れない。
  # 「パスワードは通った」という仮の札だけを持たせて、6桁を聞く画面へ
  def start_two_factor(user)
    reset_session
    session[:otp_user_id] = user.id
    session[:otp_started_at] = Time.current.to_i
    redirect_to new_two_factor_login_path
  end

  # 回数を超えた時：しばらく待ってもらう（パスワードが合っていても、この間はログインさせない）
  def too_many_attempts
    flash.now[:alert] = "ログインの試みが多すぎます。しばらく待ってから、もう一度お試しください"
    render :new, status: :too_many_requests
  end
end
