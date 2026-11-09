require "rails_helper"

RSpec.describe "課題の作成（#19）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "B").windows.create!(number: 1, title: "地震・津波・火山", measure: :plan_count) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "課題型の小窓の詳細画面に、課題を足す欄がある" do
    get window_path(window)
    expect(response.body).to include("課題を足す")
  end

  it "課題を足すと、その小窓の課題になる" do
    post window_plans_path(window), params: { plan: { title: "第1章 地震を読む" } }
    expect(response).to redirect_to(window_path(window))
    expect(window.plans.pluck(:title)).to eq([ "第1章 地震を読む" ])
  end

  it "題名が空なら保存せず、エラーを出す" do
    post window_plans_path(window), params: { plan: { title: "" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("課題を入力してください")
  end

  it "他人の小窓には課題を足せない" do
    other_window = create(:user).phases.find_by(code: "B").windows.create!(number: 1, title: "他人の窓")
    post window_plans_path(other_window), params: { plan: { title: "乗っ取り" } }
    expect(response).to have_http_status(:not_found)
    expect(other_window.plans).to be_empty
  end
end
