require "rails_helper"

RSpec.describe "Sessions（ログイン・ログアウト）", type: :request do
  let!(:user) { create(:user, name: "moga太郎", email: "taro@example.com", password: "password123") }

  describe "GET /login" do
    it "ログイン画面が表示される" do
      get login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    it "正しいメールとパスワードでログインでき、Home へ進む" do
      post login_path, params: { email: "taro@example.com", password: "password123" }
      expect(response).to redirect_to(home_path)
      follow_redirect!
      expect(response.body).to include("moga太郎").and include("局面A")
    end

    it "パスワードが違うとログインできない" do
      post login_path, params: { email: "taro@example.com", password: "wrong-pass" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("メールアドレスかパスワードが正しくありません")
    end
  end

  describe "POST /login の回数制限（#110）" do
    let(:limit) { SessionsController::LOGIN_LIMIT }

    it "10回までは、パスワードが違えば今までどおりの注意が出る" do
      limit.times do
        post login_path, params: { email: "taro@example.com", password: "wrong-pass" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it "11回目は断られ、パスワードが合っていてもログインできない" do
      limit.times { post login_path, params: { email: "taro@example.com", password: "wrong-pass" } }
      post login_path, params: { email: "taro@example.com", password: "password123" }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("ログインの試みが多すぎます")
      get home_path
      expect(response).to redirect_to(root_path)
    end

    it "3分たつと、また正しいパスワードでログインできる" do
      # 同じ機械から、別々のメールアドレスで10回（メールごとの番人には引っかからない形）
      limit.times { |i| post login_path, params: { email: "someone#{i}@example.com", password: "wrong-pass" } }
      travel(SessionsController::LOGIN_WITHIN + 1.second) do
        post login_path, params: { email: "taro@example.com", password: "password123" }
        expect(response).to redirect_to(home_path)
      end
    end
  end

  describe "POST /login のメールごとの回数制限（守り4）" do
    let(:limit) { SessionsController::EMAIL_LIMIT }

    # 毎回ちがう機械（IP アドレス）から試す＝1人目の番人（機械ごと）には引っかからない
    def post_from(number, email:, password:)
      post login_path, params: { email: email, password: password }, env: { "REMOTE_ADDR" => "203.0.113.#{number}" }
    end

    it "同じメールアドレスに、別々の機械から10回失敗すると、11回目は正しいパスワードでも断られる" do
      limit.times { |i| post_from(i + 1, email: "taro@example.com", password: "wrong-pass") }
      post_from(100, email: "taro@example.com", password: "password123")
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("ログインの試みが多すぎます")
    end

    it "大文字・前後の空白を変えても、同じメールアドレスとして数える" do
      limit.times { |i| post_from(i + 1, email: " Taro@Example.com ", password: "wrong-pass") }
      post_from(100, email: "taro@example.com", password: "password123")
      expect(response).to have_http_status(:too_many_requests)
    end

    it "別の人のメールアドレスは止まらない" do
      create(:user, email: "hanako@example.com", password: "password456", password_confirmation: "password456")
      limit.times { |i| post_from(i + 1, email: "taro@example.com", password: "wrong-pass") }
      post_from(100, email: "hanako@example.com", password: "password456")
      expect(response).to redirect_to(home_path)
    end

    it "15分たつと、また正しいパスワードでログインできる" do
      limit.times { |i| post_from(i + 1, email: "taro@example.com", password: "wrong-pass") }
      travel(SessionsController::EMAIL_WITHIN + 1.second) do
        post_from(100, email: "taro@example.com", password: "password123")
        expect(response).to redirect_to(home_path)
      end
    end
  end

  describe "DELETE /logout" do
    it "ログアウトすると TOP へ戻り、Home は開けなくなる" do
      post login_path, params: { email: "taro@example.com", password: "password123" }
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
