require "rails_helper"

RSpec.describe "パスワードを変える", type: :request do
  let!(:user) { create(:user, name: "moga太郎", email: "taro@example.com", password: "password123") }

  def log_in_as_taro
    post login_path, params: { email: "taro@example.com", password: "password123" }
  end

  def change(current:, new_password:, confirmation: new_password)
    patch password_path, params: { current_password: current, password: new_password, password_confirmation: confirmation }
  end

  it "ログインしていないと開けない" do
    get edit_password_path
    expect(response).to redirect_to(root_path)
  end

  it "Home に「パスワードを変える」の入口がある" do
    log_in_as_taro
    get home_path
    expect(response.body).to include("パスワードを変える", edit_password_path)
  end

  it "画面が開く" do
    log_in_as_taro
    get edit_password_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("今のパスワード", "新しいパスワード（確認）",
                                     "16文字ほどの長い合言葉がお勧めです")
  end

  it "今のパスワードが合えば変わり、次から新しいパスワードでログインできる。記録はそのまま" do
    log_in_as_taro
    phase = user.phases.find_by(code: "A")
    phase.update!(name: "特定社労士")

    change(current: "password123", new_password: "newpass4567")
    expect(response).to redirect_to(home_path)
    follow_redirect!
    expect(response.body).to include("パスワードを変えました")

    delete logout_path
    post login_path, params: { email: "taro@example.com", password: "password123" }
    expect(response).to have_http_status(:unprocessable_content)
    post login_path, params: { email: "taro@example.com", password: "newpass4567" }
    expect(response).to redirect_to(home_path)
    expect(phase.reload.name).to eq "特定社労士"
  end

  it "今のパスワードが違うと変わらない" do
    log_in_as_taro
    change(current: "wrong-pass", new_password: "newpass4567")
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("今のパスワードが正しくありません")
    expect(user.reload.authenticate("password123")).to be_truthy
  end

  it "確認が食い違うと変わらない" do
    log_in_as_taro
    change(current: "password123", new_password: "newpass4567", confirmation: "different99")
    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload.authenticate("password123")).to be_truthy
  end

  it "8文字より短いと変わらない" do
    log_in_as_taro
    change(current: "password123", new_password: "short")
    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload.authenticate("password123")).to be_truthy
  end

  it "新しいパスワードが空だと変わらない" do
    log_in_as_taro
    change(current: "password123", new_password: "")
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("新しいパスワードを入れてください")
  end

  it "お試し中は入口が出ず、変えることもできない" do
    post demo_session_path
    get home_path
    expect(response.body).not_to include(edit_password_path)
    get edit_password_path
    expect(response).to redirect_to(home_path)
  end
end
