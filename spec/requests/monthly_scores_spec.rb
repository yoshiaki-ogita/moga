require "rails_helper"

RSpec.describe "月ごとの成績表（#130）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }
  let(:window) { phase.windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate, target_count: 1148) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "小窓の画面に、月ごとの行と累計を出す" do
    travel_to Date.new(2026, 11, 19) do
      window.entries.create!(recorded_on: Date.new(2026, 9, 30), attempted_count: 300, achieved_count: 240)
      window.entries.create!(recorded_on: Date.new(2026, 11, 11), attempted_count: 10, achieved_count: 8)
      get window_path(window)
    end
    expect(response.body).to include("月ごとの成績表", "2026年9月", "2026年10月", "2026年11月",
                                     "300 ／ 1148（26%）", "310 ／ 1148（27%）", "―")
  end

  it "記録が無ければ、成績表は出さない" do
    get window_path(window)
    expect(response.body).not_to include("月ごとの成績表")
  end

  it "課題型の小窓には、成績表を出さない" do
    plan_window = phase.windows.create!(number: 2, title: "課題型", measure: :plan_count)
    get window_path(plan_window)
    expect(response.body).not_to include("月ごとの成績表")
  end
end
