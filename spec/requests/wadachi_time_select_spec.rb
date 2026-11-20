require "rails_helper"

RSpec.describe "轍の時刻を一覧から選ぶ（#122）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "D").windows.create!(number: 1, title: "ウォーキング", measure: :plan_count) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "始まり・終わりは、4:00〜23:45 の15分刻みの一覧で選ぶ（数字を打つ欄ではない）" do
    get diary_path("2026-11-20")
    expect(response.body).to include(%(<option value="04:00">4:00</option>), %(<option value="05:15">5:15</option>), %(<option value="23:45">23:45</option>))
    expect(response.body).not_to include(%(<option value="03:45">))
    expect(response.body).not_to match(/type="time"[^>]*name="diary\[diary_plans_attributes\]\[0\]\[starts_at\]"/)
  end

  it "一覧から選んだ時刻で保存でき、開き直すと選んだ時刻が選ばれている" do
    patch diary_path("2026-11-20"), params: { diary: { diary_plans_attributes: { "0" => { starts_at: "05:15", ends_at: "06:30", window_id: window.id } } } }
    get diary_path("2026-11-20")
    expect(response.body).to include(%(<option selected="selected" value="05:15">5:15</option>), %(<option selected="selected" value="06:30">6:30</option>))
  end

  it "一覧に無い時刻で保存してあった予定も、その時刻のまま出る（消えない）" do
    user.diaries.create!(diary_on: Date.new(2026, 11, 20), diary_plans_attributes: [ { starts_at: "03:10", ends_at: "04:20", window_id: window.id } ])
    get diary_path("2026-11-20")
    expect(response.body).to include(%(<option selected="selected" value="03:10">3:10</option>), %(<option selected="selected" value="04:20">4:20</option>))
  end
end
