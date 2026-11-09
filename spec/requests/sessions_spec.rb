require "rails_helper"

RSpec.describe "Sessions（ログイン・ログアウト）", type: :request do
  let!(:user) { create(:user, name: "荻田", email: "ogita@example.com", password: "password123") }

  describe "GET /login" do
    it "ログイン画面が表示される" do
      get login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    it "正しいメールとパスワードでログインでき、Home へ進む" do
      post login_path, params: { email: "ogita@example.com", password: "password123" }
      expect(response).to redirect_to(home_path)
      follow_redirect!
      expect(response.body).to include("荻田").and include("局面A")
    end

    it "パスワードが違うとログインできない" do
      post login_path, params: { email: "ogita@example.com", password: "wrong-pass" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("メールアドレスかパスワードが正しくありません")
    end
  end

  describe "DELETE /logout" do
    it "ログアウトすると TOP へ戻り、Home は開けなくなる" do
      post login_path, params: { email: "ogita@example.com", password: "password123" }
      delete logout_path
      expect(response).to redirect_to(root_path)
      get home_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /home（未ログイン）" do
    it "ログインしていないと TOP へ戻される" do
      get home_path
      expect(response).to redirect_to(root_path)
    end
  end
end
