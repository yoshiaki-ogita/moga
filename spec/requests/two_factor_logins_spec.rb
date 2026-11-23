require "rails_helper"

# ログインの2段目（守り2 ③）：パスワードのあと、アプリの6桁か予備の鍵
RSpec.describe "二段階認証のログイン", type: :request do
  let!(:user) { create(:user, email: "hanako@example.com") }
  let!(:backup_codes) do
    user.prepare_otp!
    user.enable_otp!(ROTP::TOTP.new(user.otp_secret).now)
    user.regenerate_backup_codes!
  end

  # 使い始めの6桁と重ならないよう、1分たった所で確かめる
  before { travel 1.minute }
  after { travel_back }

  def current_code
    ROTP::TOTP.new(user.reload.otp_secret).now
  end

  def wrong_code
    current_code == "000000" ? "111111" : "000000"
  end

  def post_password
    post login_path, params: { email: "hanako@example.com", password: "password123" }
  end

  it "パスワードが合っても、まだ中に入れず、6桁を聞く画面へ" do
    post_password
    expect(response).to redirect_to(new_two_factor_login_path)
    get home_path
    expect(response).to redirect_to(root_path)
  end

  it "6桁が合えば、ログインできる" do
    post_password
    post two_factor_login_path, params: { code: current_code }
    expect(response).to redirect_to(home_path)
    get home_path
    expect(response).to have_http_status(:ok)
  end

  it "6桁が違えば、ログインできない" do
    post_password
    post two_factor_login_path, params: { code: wrong_code }
    expect(response).to have_http_status(:unprocessable_content)
    get home_path
    expect(response).to redirect_to(root_path)
  end

  it "予備の鍵でもログインでき、残りの数を知らせる。同じ予備の鍵は2回使えない" do
    post_password
    post two_factor_login_path, params: { code: backup_codes.first }
    expect(response).to redirect_to(home_path)
    expect(flash[:notice]).to include("残り15個")

    delete logout_path
    post_password
    post two_factor_login_path, params: { code: backup_codes.first }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "パスワードを通らずに、6桁の画面へは来られない" do
    get new_two_factor_login_path
    expect(response).to redirect_to(login_path)
    post two_factor_login_path, params: { code: current_code }
    expect(response).to redirect_to(login_path)
  end

  it "パスワードが通ってから5分を過ぎると、最初からやり直し" do
    post_password
    travel 6.minutes
    post two_factor_login_path, params: { code: current_code }
    expect(response).to redirect_to(login_path)
  end

  it "6桁を総当たりで試すと、11回目で止まる（合っている6桁でも、この間は入れない）" do
    post_password
    10.times { post two_factor_login_path, params: { code: wrong_code } }
    post two_factor_login_path, params: { code: current_code }
    expect(response).to have_http_status(:too_many_requests)
  end

  it "二段階認証を使わない人は、これまでどおりパスワードだけで入れる" do
    create(:user, email: "taro@example.com")
    post login_path, params: { email: "taro@example.com", password: "password123" }
    expect(response).to redirect_to(home_path)
  end

  describe "やめる" do
    before do
      post_password
      post two_factor_login_path, params: { code: current_code }
      travel 1.minute
    end

    it "パスワードと6桁が合えば、やめられる。次からはパスワードだけで入れる" do
      delete two_factor_path, params: { current_password: "password123", code: current_code }
      expect(response).to redirect_to(two_factor_path)
      expect(user.reload.otp_enabled?).to be false

      delete logout_path
      post_password
      expect(response).to redirect_to(home_path)
    end

    it "スマホを失くしても、パスワードと予備の鍵でやめられる" do
      delete two_factor_path, params: { current_password: "password123", code: backup_codes.last }
      expect(user.reload.otp_enabled?).to be false
    end

    it "パスワードが違えば、やめられない" do
      delete two_factor_path, params: { current_password: "wrong-password", code: current_code }
      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.otp_enabled?).to be true
    end
  end
end
