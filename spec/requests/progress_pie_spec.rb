require "rails_helper"

RSpec.describe "進捗率の円グラフ（#29）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase_a) { user.phases.find_by(code: "A") }
  let!(:window) do
    phase_a.windows.create!(number: 1, title: "過去問", measure: :achievement_rate).tap do |w|
      w.entries.create!(recorded_on: Date.current, attempted_count: 20, achieved_count: 16)
      w.entries.create!(recorded_on: Date.current, attempted_count: 10, achieved_count: 10)
    end
  end

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "小窓の画面に、％と割り算のもとの数が出る（26 / 30 → 87%）" do
    get window_path(window)
    expect(response.body).to include("--pct: 87;", "87%", "26 / 30")
  end

  it "大窓の画面に、小窓の平均の％が出る" do
    get phase_path(phase_a)
    expect(response.body).to include("--pct: 87;", "小窓 1 個の平均")
  end

  it "Home に、全体の％が出る（87% ÷ 8 → 11%）" do
    get home_path
    expect(response.body).to include("--pct: 11;", "全体の進捗率")
  end
end
