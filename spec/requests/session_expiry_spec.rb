require "rails_helper"

RSpec.describe "ログインしたままの期限（#114）", type: :request do
  let(:user) { create(:user, password: "password123") }

  it "ログインすると、セッションの合札に2週間の期限が付く" do
    post login_path, params: { email: user.email, password: "password123" }

    cookie = Array(response.headers["set-cookie"]).join("\n")
    expect(cookie).to match(/_moga_session=.*expires=/i)
  end

  it "2週間を過ぎると、ログインし直しになる" do
    post login_path, params: { email: user.email, password: "password123" }

    travel 15.days do
      get home_path
      expect(response).to redirect_to(root_path)
    end
  end
end
