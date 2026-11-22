# パスワードを変える画面（ログインしている本人だけ）
#   今のパスワードを確かめてから、新しいパスワードに変える。
#   記録（大窓・小窓・轍）には一切さわらない。
class PasswordsController < ApplicationController
  # 今のパスワードを総当たりで試されないよう、ログインと同じく3分間に10回まで
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  LIMIT = 10
  WITHIN = 3.minutes

  before_action :require_login
  before_action :reject_demo
  rate_limit to: LIMIT, within: WITHIN, only: :update, store: RATE_LIMIT_STORE,
             with: -> { too_many_attempts }

  def edit
  end

  def update
    error = password_error
    return render_error(error) if error

    # 合言葉の札を新しくしてから入り直す（古い札では入れなくなる）
    log_in(current_user)
    redirect_to home_path, notice: "パスワードを変えました。次からは新しいパスワードでログインしてください"
  end

  private

  # お試しの見本の利用者は、パスワードを変えられない
  def reject_demo
    return unless demo?

    redirect_to home_path, alert: "お試し中は見るだけです"
  end

  # 変えられた時は nil、変えられなかった時はその理由を返す
  def password_error
    return "今のパスワードが正しくありません" unless current_user.authenticate(params[:current_password].to_s)
    return "新しいパスワードを入れてください" if params[:password].blank?
    return if current_user.update(params.permit(:password, :password_confirmation))

    current_user.errors.full_messages.join("、")
  end

  def render_error(message)
    flash.now[:alert] = message
    render :edit, status: :unprocessable_content
  end

  def too_many_attempts
    flash.now[:alert] = "試みが多すぎます。しばらく待ってから、もう一度お試しください"
    render :edit, status: :too_many_requests
  end
end
