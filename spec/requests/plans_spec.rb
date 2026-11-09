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

RSpec.describe "課題の一覧（#20）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "B").windows.create!(number: 1, title: "地震・津波・火山", measure: :plan_count) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "課題が「まだ」「済み」に分かれて並び、済みには済んだ日時が出る" do
    window.plans.create!(title: "第1章 地震を読む")
    window.plans.create!(title: "第2章 津波を読む", done_at: Time.zone.local(2026, 11, 10, 9, 30))
    get window_path(window)
    expect(response.body).to include("まだ（1）", "済み（1）", "第1章 地震を読む", "第2章 津波を読む")
    expect(response.body).to include("済んだ日時：2026年11月10日 09:30")
    expect(response.body.index("第1章 地震を読む")).to be < response.body.index("済み（1）")
  end

  it "ほかの小窓の課題は出ない" do
    other = user.phases.find_by(code: "B").windows.create!(number: 2, title: "風水害", measure: :plan_count)
    other.plans.create!(title: "第5章 台風を読む")
    get window_path(window)
    expect(response.body).not_to include("第5章 台風を読む")
  end
end

RSpec.describe "課題の編集（#21）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "B").windows.create!(number: 1, title: "地震・津波・火山", measure: :plan_count) }
  let!(:plan) { window.plans.create!(title: "第1章") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "一覧に「直す」があり、編集画面が開ける" do
    get window_path(window)
    expect(response.body).to include(edit_plan_path(plan))
    get edit_plan_path(plan)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("課題を直す")
  end

  it "題名を直すと、一覧の表示が変わる" do
    patch plan_path(plan), params: { plan: { title: "第1章 地震を読む" } }
    expect(response).to redirect_to(window_path(window))
    get window_path(window)
    expect(response.body).to include("第1章 地震を読む")
  end

  it "題名を空にはできない" do
    patch plan_path(plan), params: { plan: { title: "" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(plan.reload.title).to eq("第1章")
  end

  it "他人の課題は編集できない" do
    other_plan = create(:user).phases.find_by(code: "B").windows.create!(number: 1, title: "他人の窓").plans.create!(title: "他人の課題")
    patch plan_path(other_plan), params: { plan: { title: "乗っ取り" } }
    expect(response).to have_http_status(:not_found)
    expect(other_plan.reload.title).to eq("他人の課題")
  end
end

RSpec.describe "課題の削除（#22）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "B").windows.create!(number: 1, title: "地震・津波・火山", measure: :plan_count) }
  let!(:plan) { window.plans.create!(title: "第1章 地震を読む") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "一覧に確認つきの「消す」がある" do
    get window_path(window)
    expect(response.body).to include("data-turbo-confirm", "課題「第1章 地震を読む」を消します")
  end

  it "削除すると一覧から消える" do
    expect { delete plan_path(plan) }.to change(Plan, :count).by(-1)
    expect(response).to redirect_to(window_path(window))
    follow_redirect!
    expect(response.body).to include("まだ（0）")
  end

  it "他人の課題は消せない" do
    other_plan = create(:user).phases.find_by(code: "B").windows.create!(number: 1, title: "他人の窓").plans.create!(title: "他人の課題")
    expect { delete plan_path(other_plan) }.not_to change(Plan, :count)
    expect(response).to have_http_status(:not_found)
  end
end
