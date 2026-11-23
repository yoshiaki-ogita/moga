require "rails_helper"

# 二段の鍵の設定画面（守り2 ②）
RSpec.describe "二段の鍵の設定", type: :request do
  let!(:user) { create(:user, email: "hanako@example.com") }

  def log_in
    post login_path, params: { email: "hanako@example.com", password: "password123" }
  end

  def current_code
    ROTP::TOTP.new(user.reload.otp_secret).now
  end

  it "ログインしていなければ、TOP へ" do
    get two_factor_path
    expect(response).to redirect_to(root_path)
  end

  context "ログインしている時" do
    before { log_in }

    it "今の様子の画面に「まだ使っていません」と「二段の鍵を使う」が出る" do
      get two_factor_path
      expect(response.body).to include("二段の鍵は、まだ使っていません")
      expect(response.body).to include(new_two_factor_path)
    end

    it "Home に「二段の鍵」の入口がある" do
      get home_path
      expect(response.body).to include(two_factor_path)
    end

    it "設定の画面に QR コードが出て、読み直しても同じ種のまま" do
      get new_two_factor_path
      expect(response.body).to include("<svg")
      first_secret = user.reload.otp_secret
      expect(first_secret).to be_present

      get new_two_factor_path
      expect(user.reload.otp_secret).to eq(first_secret)
    end

    it "正しい6桁で使い始め、予備の鍵16個が一度だけ出る（ブラウザに残さない）" do
      get new_two_factor_path
      post two_factor_path, params: { code: current_code }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(user.reload.otp_enabled?).to be true
      codes = response.body.scan(/<li>([a-z2-9]{5}-[a-z2-9]{5})<\/li>/).flatten
      expect(codes.size).to eq(16)
      expect(user.remaining_backup_codes_count).to eq(16)

      get two_factor_path
      expect(response.body).to include("二段の鍵を使っています")
      expect(response.body).to include("16個")
      expect(response.body).not_to include(codes.first)
    end

    it "違う6桁では使い始めない" do
      get new_two_factor_path
      wrong = current_code == "000000" ? "111111" : "000000"
      post two_factor_path, params: { code: wrong }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("6桁の数字が合いません")
      expect(user.reload.otp_enabled?).to be false
    end

    it "使っている人がもう一度設定の画面を開くと、今の様子の画面へ（種は変わらない）" do
      get new_two_factor_path
      post two_factor_path, params: { code: current_code }
      secret = user.reload.otp_secret

      get new_two_factor_path
      expect(response).to redirect_to(two_factor_path)
      expect(user.reload.otp_secret).to eq(secret)
    end

    it "6桁を総当たりで試すと、11回目で止まる" do
      get new_two_factor_path
      wrong = current_code == "000000" ? "111111" : "000000"
      10.times { post two_factor_path, params: { code: wrong } }
      post two_factor_path, params: { code: wrong }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  it "お試しの見本の利用者は、二段の鍵の画面を使えない" do
    post demo_session_path
    get new_two_factor_path
    expect(response).to redirect_to(home_path)
    expect(DemoAccount.user.reload.otp_secret).to be_nil
  end
end
