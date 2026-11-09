require "rails_helper"

RSpec.describe "小窓の作成（#14）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "作成画面が開ける" do
    get new_phase_window_path(phase)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("小窓を作る")
  end

  it "小窓を作ると、大窓の画面に出る" do
    post phase_windows_path(phase), params: { window: { number: 1, title: "労働基準法", measure: "achievement_rate" } }
    expect(response).to redirect_to(phase_path(phase))
    expect(phase.windows.first).to have_attributes(number: 1, title: "労働基準法", measure: "achievement_rate")

    get phase_path(phase)
    expect(response.body).to include("労働基準法")
  end

  it "題名が空なら保存せず、エラーを出す" do
    post phase_windows_path(phase), params: { window: { number: 1, title: "", measure: "plan_count" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("小窓の題名を入力してください")
  end

  it "1つの大窓に9つ目は作れない" do
    Window::NUMBERS.each { |n| phase.windows.create!(number: n, title: "窓#{n}") }
    get new_phase_window_path(phase)
    expect(response).to redirect_to(phase_path(phase))
    expect {
      post phase_windows_path(phase), params: { window: { number: 1, title: "9つ目" } }
    }.not_to change(Window, :count)
  end

  it "他人の大窓には小窓を作れない" do
    other_phase = create(:user).phases.find_by(code: "A")
    post phase_windows_path(other_phase), params: { window: { number: 1, title: "乗っ取り" } }
    expect(response).to have_http_status(:not_found)
    expect(other_phase.windows).to be_empty
  end
end

RSpec.describe "空いたマスから小窓を作る（#15）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "押したマスの番号が、最初から選ばれている" do
    get new_phase_window_path(phase, number: 5)
    expect(response.body).to include('<option selected="selected" value="5">窓5</option>')
  end
end

RSpec.describe "小窓の詳細（#16）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "大窓の画面の小窓を押すと、詳細画面が開く" do
    window = phase.windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate)
    get phase_path(phase)
    expect(response.body).to include(window_path(window))

    get window_path(window)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("窓1 労働基準法", "達成率型", "記録")
  end

  it "課題型なら、課題の入口が出る" do
    window = phase.windows.create!(number: 2, title: "第1章〜第4章", measure: :plan_count)
    get window_path(window)
    expect(response.body).to include("課題型", "<h2>課題</h2>")
  end

  it "パンくずに Home ＞ 大窓 ＞ 小窓 が出る" do
    window = phase.windows.create!(number: 1, title: "労働基準法")
    get window_path(window)
    expect(response.body).to include("A 局面A", "窓1 労働基準法", home_path)
  end

  it "他人の小窓は開けない" do
    other_window = create(:user).phases.find_by(code: "A").windows.create!(number: 1, title: "他人の窓")
    get window_path(other_window)
    expect(response).to have_http_status(:not_found)
  end
end

RSpec.describe "小窓の編集（#17）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }
  let!(:window) { phase.windows.create!(number: 1, title: "労基法", measure: :plan_count) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "編集画面が開ける" do
    get edit_window_path(window)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("小窓を直す")
  end

  it "題名を直すと、大窓の画面の表示が変わる" do
    patch window_path(window), params: { window: { title: "労働基準法" } }
    expect(response).to redirect_to(window_path(window))
    get phase_path(phase)
    expect(response.body).to include("労働基準法")
    expect(response.body).not_to include("労基法<")
  end

  it "数え方はいつでも変えられる" do
    patch window_path(window), params: { window: { measure: "achievement_rate" } }
    expect(window.reload).to be_achievement_rate
  end

  it "ほかの小窓と同じ番号には変えられない" do
    phase.windows.create!(number: 2, title: "労災保険法")
    patch window_path(window), params: { window: { number: 2 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(window.reload.number).to eq(1)
  end

  it "他人の小窓は編集できない" do
    other_window = create(:user).phases.find_by(code: "A").windows.create!(number: 1, title: "他人の窓")
    patch window_path(other_window), params: { window: { title: "乗っ取り" } }
    expect(response).to have_http_status(:not_found)
    expect(other_window.reload.title).to eq("他人の窓")
  end
end
