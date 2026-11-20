require "rails_helper"

RSpec.describe "△ の予定を明日に回す（#123）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "H").windows.create!(number: 3, title: "継続受講", measure: :plan_count) }
  let(:diary) { user.diaries.create!(diary_on: Date.new(2026, 11, 20)) }
  let!(:plan) { diary.diary_plans.create!(starts_at: "05:00", ends_at: "06:30", window: window, memo: "Railsの復習", outcome: "missed") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "△ の行にだけ「明日に回す ▶」が出る" do
    get diary_path("2026-11-20")
    expect(response.body).to include("△ の予定は、明日にもう一度", "明日に回す ▶", carry_diary_plan_path(plan))

    plan.update!(outcome: "kept")
    get diary_path("2026-11-20")
    expect(response.body).not_to include("明日に回す ▶")
  end

  it "押すと、明日の轍に同じ予定が写る（2回押しても1つだけ）" do
    post carry_diary_plan_path(plan)
    expect(response).to redirect_to(diary_path("2026-11-20"))
    follow_redirect!
    expect(response.body).to include("「5:00〜6:30 H3」を11月21日（土）の轍に回しました")

    tomorrow = user.diaries.find_by(diary_on: Date.new(2026, 11, 21))
    copied = tomorrow.diary_plans.sole
    expect([ copied.time_label, copied.window_id, copied.memo, copied.outcome ]).to eq([ "5:00〜6:30", window.id, "Railsの復習", nil ])

    post carry_diary_plan_path(plan)
    expect(tomorrow.reload.diary_plans.count).to eq 1
  end

  it "他人の予定は回せない" do
    other = create(:user)
    other_window = other.phases.find_by(code: "A").windows.create!(number: 1, title: "他人の小窓", measure: :plan_count)
    other_plan = other.diaries.create!(diary_on: Date.new(2026, 11, 20)).diary_plans.create!(starts_at: "05:00", ends_at: "06:00", window: other_window)
    post carry_diary_plan_path(other_plan)
    expect(response).to have_http_status(:not_found)
    expect(other.diaries.count).to eq 1
  end
end
