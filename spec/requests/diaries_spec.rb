require "rails_helper"

RSpec.describe "わたしの轍（PR1：前の日に書く①〜③）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let!(:window) { user.phases.find_by(code: "D").windows.create!(number: 1, title: "長距離ウォーキング") }

  context "ログインしていない時" do
    it "轍の一覧は開けず、TOPへ戻る" do
      get diaries_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "ログインしている時" do
    before do
      post login_path, params: { email: user.email, password: "password123" }
    end

    it "Home の真ん中の丸から、今日の轍へ行ける" do
      get home_path
      expect(response.body).to include(diary_path(Date.current), "👣 轍")
    end

    it "まだ書いていない日の轍も開け、空の行動予定の行と①〜③の欄がある" do
      get diary_path("2026-11-17")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("11月17日（火）の轍", "① 行動予定", "② 今日の一言", "③ 今日必ずやること", "D1 長距離ウォーキング")
      expect(user.diaries).to be_empty
    end

    it "前の日・次の日へのリンクがある" do
      get diary_path("2026-11-17")
      expect(response.body).to include(diary_path("2026-11-16"), diary_path("2026-11-18"))
    end

    it "日付でない物を入れると、見つからない（404）" do
      get diary_path("abc")
      expect(response).to have_http_status(:not_found)
    end

    it "①〜③を保存すると、その日の轍が1つでき、空の行は残らない" do
      patch diary_path("2026-11-17"), params: { diary: {
        word: "一歩ずつ、今日も前へ。", must_do: "ウォーキング 8km",
        diary_plans_attributes: {
          "0" => { starts_at: "07:30", ends_at: "10:00", window_id: window.id, memo: "川沿いを歩く" },
          "1" => { starts_at: "", ends_at: "", window_id: "", memo: "" }
        }
      } }
      expect(response).to redirect_to(diary_path("2026-11-17"))
      diary = user.diaries.find_by(diary_on: Date.new(2026, 11, 17))
      expect([ diary.word, diary.must_do, diary.diary_plans.count ]).to eq([ "一歩ずつ、今日も前へ。", "ウォーキング 8km", 1 ])
      follow_redirect!
      expect(response.body).to include("11月17日（火）の轍を保存しました")
    end

    it "2回目の保存は、同じ日の轍を直す（2つにならない）" do
      2.times { |i| patch diary_path("2026-11-17"), params: { diary: { word: "一言#{i}" } } }
      expect(user.diaries.count).to eq(1)
      expect(user.diaries.first.word).to eq("一言1")
    end

    it "行動予定の行に「消す」を付けて保存すると、その行が消える" do
      diary = user.diaries.create!(diary_on: Date.new(2026, 11, 17), diary_plans_attributes: [ { starts_at: "05:00", ends_at: "06:30", window_id: window.id } ])
      plan = diary.diary_plans.first
      patch diary_path("2026-11-17"), params: { diary: { diary_plans_attributes: { "0" => { id: plan.id, _destroy: "1" } } } }
      expect(diary.diary_plans.reload).to be_empty
    end

    it "終わりが始まりより前だと保存せず、エラーを出す" do
      patch diary_path("2026-11-17"), params: { diary: { diary_plans_attributes: { "0" => { starts_at: "10:00", ends_at: "09:00", window_id: window.id } } } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("行動予定の終わりは始まりより後の時刻にしてください")
      expect(user.diaries).to be_empty
    end

    it "他人の小窓を行動予定に入れることはできない" do
      other_window = create(:user).phases.find_by(code: "A").windows.create!(number: 1, title: "他人の窓")
      patch diary_path("2026-11-17"), params: { diary: { diary_plans_attributes: { "0" => { starts_at: "05:00", ends_at: "06:00", window_id: other_window.id } } } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(DiaryPlan.count).to eq(0)
    end

    it "1日の轍に、④の評価の5項目と a〜e の意味が出る" do
      get diary_path("2026-11-17")
      expect(response.body).to include("④ 今日1日の自分の行動の評価", "心（メンタル）", "技（スキル）", "体（健康）", "生活", "今日は全体で？",
                                       "a：良い！", "e：負けるな！！")
      # 丸い印（label）を押すと、その評価が選ばれる
      expect(response.body).to include('for="diary_mind_grade_b"', 'id="diary_mind_grade_b"')
    end

    it "④の評価とコメントを保存できる" do
      patch diary_path("2026-11-17"), params: { diary: { mind_grade: "b", mind_comment: "落ち着いて過ごせた", overall_grade: "a" } }
      diary = user.diaries.find_by(diary_on: Date.new(2026, 11, 17))
      expect([ diary.mind_grade, diary.mind_comment, diary.overall_grade ]).to eq([ "b", "落ち着いて過ごせた", "a" ])
      follow_redirect!
      expect(response.body).to include('value="b" checked="checked" name="diary[mind_grade]"')
    end

    it "a〜e 以外の評価は保存しない" do
      patch diary_path("2026-11-17"), params: { diary: { body_grade: "z" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(user.diaries).to be_empty
    end

    it "一覧に「今日は全体で？」の評価が出る（まだなら「ー」）" do
      user.diaries.create!(diary_on: Date.new(2026, 11, 16), word: "評価あり", overall_grade: "a")
      user.diaries.create!(diary_on: Date.new(2026, 11, 17), word: "評価なし")
      get diaries_path
      expect(response.body).to include("wadachi-list__grade--a", "wadachi-list__grade--none")
    end

    it "一覧は新しい日が上に並び、題名の「轍」に読み仮名が付く" do
      user.diaries.create!(diary_on: Date.new(2026, 11, 16), word: "古い一言")
      user.diaries.create!(diary_on: Date.new(2026, 11, 17), word: "新しい一言")
      get diaries_path
      expect(response.body).to include("<rt class=\"wadachi__ruby\">わだち</rt>", "＋ 明日の轍を書く")
      expect(response.body.index("新しい一言")).to be < response.body.index("古い一言")
    end

    it "轍がまだ無い時は、始め方が出る" do
      get diaries_path
      expect(response.body).to include("轍はまだありません")
    end

    it "他人の轍は一覧に出ない" do
      create(:user).diaries.create!(diary_on: Date.current, word: "他人の一言")
      get diaries_path
      expect(response.body).not_to include("他人の一言")
    end
  end
end
