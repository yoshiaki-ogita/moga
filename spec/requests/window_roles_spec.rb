require "rails_helper"

RSpec.describe "小窓の配列の決まり 6＝核・8＝シナプス（#117）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "B") }
  let(:rule) { "窓6＝このテーマの核　窓8＝シナプス（1〜7を結ぶ糸）" }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "大窓の画面の曼荼羅の下に、決まりを1行で示す" do
    get phase_path(phase)
    expect(response.body).to include(rule)
  end

  it "まだ小窓の無いマスでも、窓6に「核」、窓8に「シナプス」と添える" do
    get phase_path(phase)
    expect(response.body).to include(%(<span class="mandala__role">核</span>), %(<span class="mandala__role">シナプス</span>))
  end

  it "作った小窓のマスにも、役割を添える（窓1には添えない）" do
    phase.windows.create!(number: 6, title: "防災の芯", measure: :plan_count)
    phase.windows.create!(number: 1, title: "備蓄", measure: :plan_count)
    get phase_path(phase)
    expect(response.body.scan(%(class="mandala__role")).size).to eq 2
    expect(response.body).to include("防災の芯")
  end

  it "小窓を作る画面にも、同じ決まりを示す" do
    get new_phase_window_path(phase)
    expect(response.body).to include(rule)
  end
end
