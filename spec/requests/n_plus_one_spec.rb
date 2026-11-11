require "rails_helper"

# N+1問題（#34）。テストでは Bullet が N+1 を見つけるとエラーにする（config/environments/test.rb）
# 大窓・小窓・課題・記録をたくさん作っても、Home と大窓の画面がエラーにならないことを確かめる
RSpec.describe "N+1問題が出ない（#34）", type: :request do
  let(:user) { create(:user, password: "password123") }

  before do
    %w[A B C].each do |code|
      phase = user.phases.find_by(code: code)
      plan_window = phase.windows.create!(number: 1, title: "課題の窓", measure: :plan_count)
      2.times { |i| plan_window.plans.create!(title: "課題#{i}", done_at: (Time.current if i.zero?)) }
      rate_window = phase.windows.create!(number: 2, title: "記録の窓", measure: :achievement_rate)
      2.times { rate_window.entries.create!(recorded_on: Date.current, attempted_count: 10, achieved_count: 5) }
    end
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "Home（大窓8つ × 小窓）" do
    get home_path
    expect(response).to have_http_status(:ok)
  end

  it "大窓の画面（小窓 × 課題・記録）" do
    get phase_path(user.phases.find_by(code: "A"))
    expect(response).to have_http_status(:ok)
  end
end
