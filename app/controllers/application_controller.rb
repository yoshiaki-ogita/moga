class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?, :demo?

  # お試し中に許す書き込み：ログアウト、ログイン、お試しに入り直す、新しく登録する
  DEMO_ALLOWED = %w[sessions#destroy sessions#create demo_sessions#create users#create].freeze

  # お試しの見本の利用者は見るだけ（書き込み・削除を止める）
  before_action :block_demo_writes

  private

  # ログイン状態にする（セッションに利用者の番号を覚えさせる）
  def log_in(user)
    reset_session
    session[:user_id] = user.id
  end

  # いまログインしている利用者（いなければ nil）
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  # お試しの見本の利用者でログインしているか
  def demo?
    current_user&.email == DemoAccount::EMAIL
  end

  def block_demo_writes
    return if request.get? || request.head? || !demo?
    return if DEMO_ALLOWED.include?("#{controller_name}##{action_name}")

    redirect_back fallback_location: home_path, status: :see_other,
                  alert: "お試し中は見るだけです。書き込むには、ログアウトして自分で登録してください"
  end

  # ログアウトする（セッションを空にする）
  def log_out
    reset_session
    @current_user = nil
  end

  # ログインしていない人を TOP ページへ戻す（11/7 決裁）
  def require_login
    return if logged_in?

    redirect_to root_path, alert: "ログインしてください"
  end
end
