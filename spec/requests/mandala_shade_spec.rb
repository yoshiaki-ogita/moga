require "rails_helper"

RSpec.describe "曼荼羅64の青の濃淡（#30）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase_a) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "0% のマスは --pct: 0（白）" do
    get home_path
    expect(response.body).to include('style="--pct: 0;"')
    expect(response.body).not_to include("mandala__cell--dark")
  end

  it "進捗率を変えると、大窓の画面の小窓のマスの濃さが変わる" do
    window = phase_a.windows.create!(number: 1, title: "労働基準法", measure: :plan_count)
    plan = window.plans.create!(title: "第1章")
    window.plans.create!(title: "第2章")

    get phase_path(phase_a)
    expect(response.body).to include('style="--pct: 0;"')

    plan.update!(done_at: Time.current)
    get phase_path(phase_a)
    expect(response.body).to include('style="--pct: 50;"', "50%")
  end

  it "Home の大窓のマスも、その大窓の％で塗られ、濃いマスは字が白になる" do
    window = phase_a.windows.create!(number: 1, title: "労働基準法", measure: :plan_count)
    window.plans.create!(title: "第1章", done_at: Time.current)
    get home_path
    expect(response.body).to include('style="--pct: 100;"', "mandala__cell--dark")
  end
end
