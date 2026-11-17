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

  # わたしの轍（11/15〜11/17 に足した画面）も、N+1 が出ないことを確かめる
  context "わたしの轍" do
    before do
      windows = [ %w[A 1], %w[B 2], %w[C 1] ].map { |code, number| user.phases.find_by(code: code).windows.find_by(number: number) }
      3.times do |i|
        user.diaries.create!(diary_on: Date.new(2026, 11, 15 + i), word: "一言#{i}", diary_plans_attributes: [
          { starts_at: "05:00", ends_at: "06:30", window_id: windows[0].id },
          { starts_at: "07:30", ends_at: "10:00", window_id: windows[1].id },
          { starts_at: "20:00", ends_at: "21:00", window_id: windows[2].id }
        ])
      end
    end

    it "轍の一覧（轍 3日分）" do
      get diaries_path
      expect(response).to have_http_status(:ok)
    end

    it "1日の轍（行動予定 × 小窓 × 大窓）" do
      get diary_path("2026-11-17")
      expect(response).to have_http_status(:ok)
    end
  end
end
