require "rails_helper"

RSpec.describe Diary, type: :model do
  let(:user) { create(:user) }
  let(:window) { user.phases.find_by(code: "D").windows.create!(number: 1, title: "長距離ウォーキング") }

  it "1人の利用者に、同じ日の轍は1つだけ" do
    user.diaries.create!(diary_on: Date.new(2026, 11, 17))
    duplicate = user.diaries.build(diary_on: Date.new(2026, 11, 17))
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:diary_on]).to include("はすでに使われています")
  end

  it "別の人なら、同じ日の轍を持てる" do
    user.diaries.create!(diary_on: Date.new(2026, 11, 17))
    expect(create(:user).diaries.build(diary_on: Date.new(2026, 11, 17))).to be_valid
  end

  it "今日の一言は50文字まで" do
    expect(user.diaries.build(diary_on: Date.current, word: "あ" * 51)).not_to be_valid
  end

  it "日付は「11月17日（火）」の形で出る" do
    expect(user.diaries.build(diary_on: Date.new(2026, 11, 17)).date_label).to eq("11月17日（火）")
  end

  it ".for は、まだ無い日なら保存前の新しい轍を返し、ある日ならその轍を返す" do
    expect(Diary.for(user, Date.new(2026, 11, 17))).to be_new_record
    saved = user.diaries.create!(diary_on: Date.new(2026, 11, 18))
    expect(Diary.for(user, Date.new(2026, 11, 18))).to eq(saved)
  end

  it "空の行動予定の行は保存しない" do
    diary = user.diaries.create!(diary_on: Date.current, diary_plans_attributes: [
      { starts_at: "05:00", ends_at: "06:30", window_id: window.id, memo: "川沿い" },
      { starts_at: "", ends_at: "", window_id: "", memo: "" }
    ])
    expect(diary.diary_plans.count).to eq(1)
  end

  it "④の評価は a〜e のどれかか、空（まだ付けていない）" do
    expect(user.diaries.build(diary_on: Date.current, mind_grade: "a", overall_grade: "e")).to be_valid
    expect(user.diaries.build(diary_on: Date.current, mind_grade: nil)).to be_valid
    expect(user.diaries.build(diary_on: Date.current, skill_grade: "f")).not_to be_valid
  end

  it "④のコメントは50文字まで" do
    expect(user.diaries.build(diary_on: Date.current, life_comment: "あ" * 51)).not_to be_valid
  end

  it "④の項目と a〜e の意味は、本人の言葉で並ぶ" do
    expect(Diary::REVIEW_ITEMS.values).to eq([ "心（メンタル）", "技（スキル）", "体（健康）", "生活", "今日は全体で？" ])
    expect(Diary::GRADES.values).to eq([ "良い！", "やや良い", "まぁまぁ", "明日こそ", "負けるな！！" ])
  end

  it "轍を消すと、中の行動予定も消える" do
    diary = user.diaries.create!(diary_on: Date.current, diary_plans_attributes: [ { starts_at: "05:00", ends_at: "06:30", window_id: window.id } ])
    expect { diary.destroy }.to change(DiaryPlan, :count).by(-1)
  end
end

RSpec.describe DiaryPlan, type: :model do
  let(:user) { create(:user) }
  let(:diary) { user.diaries.create!(diary_on: Date.current) }
  let(:window) { user.phases.find_by(code: "D").windows.create!(number: 1, title: "長距離ウォーキング") }

  it "始まり・終わり・小窓があれば保存できる" do
    expect(diary.diary_plans.build(starts_at: "05:00", ends_at: "06:30", window: window)).to be_valid
  end

  it "終わりが始まりより前だと保存できない" do
    plan = diary.diary_plans.build(starts_at: "07:00", ends_at: "06:30", window: window)
    expect(plan).not_to be_valid
    expect(plan.errors[:ends_at]).to include("は始まりより後の時刻にしてください")
  end

  it "小窓を選ばないと保存できない" do
    plan = diary.diary_plans.build(starts_at: "05:00", ends_at: "06:30")
    expect(plan).not_to be_valid
    expect(plan.errors[:window]).to include("を選んでください")
  end

  it "他人の小窓は選べない" do
    other_window = create(:user).phases.find_by(code: "A").windows.create!(number: 1, title: "他人の窓")
    expect(diary.diary_plans.build(starts_at: "05:00", ends_at: "06:30", window: other_window)).not_to be_valid
  end

  it "時間帯は「5:00〜6:30」の形で出る" do
    expect(diary.diary_plans.build(starts_at: "05:00", ends_at: "06:30", window: window).time_label).to eq("5:00〜6:30")
  end

  it "小窓を消すと、その小窓の行動予定も消える（轍は残る）" do
    diary.diary_plans.create!(starts_at: "05:00", ends_at: "06:30", window: window)
    expect { window.destroy }.to change(DiaryPlan, :count).by(-1)
    expect(Diary.exists?(diary.id)).to be(true)
  end

  describe "⑤⑥（その日の終わりに書く）" do
    it "⑤⑥は51文字以上は保存できない" do
      diary.redo_1 = "あ" * 51
      diary.joy = "い" * 51
      expect(diary).not_to be_valid
      expect(diary.errors[:redo_1]).to be_present
      expect(diary.errors[:joy]).to be_present
    end

    it "⑤をまだ1つも書いていない日は、励ましを出さない" do
      expect(diary.redo_cheer).to be_nil
    end

    it "⑤が3つに足りない時は「あと◯つ」と励ます（保存はできる）" do
      diary.redo_1 = "朝の復習を先にやる"
      diary.redo_3 = "早めに寝る"
      expect(diary).to be_valid
      expect(diary.redo_cheer).to eq("⑤はあと1つ。もう一歩！")
    end

    it "⑤が3つ以上なら達成を伝える" do
      diary.assign_attributes(redo_1: "一", redo_2: "二", redo_3: "三", redo_4: "四")
      expect(diary.redo_cheer).to eq("⑤ 3つ以上達成！")
    end
  end

  describe "①の実際（PR4）" do
    let(:diary) { user.diaries.create!(diary_on: Date.new(2026, 11, 17)) }
    let(:plan) { diary.diary_plans.create!(starts_at: "07:30", ends_at: "10:00", window: window) }

    it "まだ確かめていない行は、実際が無い" do
      expect(plan.actual_range).to be_nil
      expect(plan).not_to be_actual
    end

    it "◎ 予定どおりなら、予定の時刻が実際になる（#123）" do
      plan.update!(outcome: "kept")
      expect(plan.actual_range.map { |t| t.strftime("%H:%M") }).to eq(%w[07:30 10:00])
    end

    it "○ 少しずれたなら、時刻を書かなくても予定の時刻で数える（#123）" do
      plan.update!(outcome: "shifted")
      expect(plan.actual_range.map { |t| t.strftime("%H:%M") }).to eq(%w[07:30 10:00])
    end

    it "○ 少しずれた行に、前に書いた実際の時刻があれば、それを使う" do
      plan.update!(outcome: "shifted", actual_starts_at: "08:00", actual_ends_at: "10:30")
      expect(plan.actual_range.map { |t| t.strftime("%H:%M") }).to eq(%w[08:00 10:30])
    end

    it "△ できなかった行は、できた時間に入れない（確かめたことにはなる）" do
      plan.update!(outcome: "missed")
      expect(plan.actual_range).to be_nil
      expect(plan).to be_checked
      expect(plan).to be_missed
    end

    it "◎○△ 以外は保存できない" do
      plan.outcome = "perfect"
      expect(plan).not_to be_valid
    end

    it "実際の時刻は片方だけでは保存できない" do
      plan.actual_starts_at = "08:00"
      expect(plan).not_to be_valid
      expect(plan.errors[:base]).to include("実際の時刻は、始まりと終わりの両方を書いてください")
    end

    it "実際の終わりは、実際の始まりより後" do
      plan.assign_attributes(actual_starts_at: "10:00", actual_ends_at: "09:00")
      expect(plan).not_to be_valid
    end

    it "小窓の記号は「D1」、大窓は「D」" do
      expect([ plan.window_code, plan.phase_code ]).to eq(%w[D1 D])
    end

    it "④⑤⑥のどれかを書いたら、寝る前の部分を書いたことになる" do
      expect(diary).not_to be_evening_written
      diary.joy = "友人から電話"
      expect(diary).to be_evening_written
    end
  end

  it "①は日本の時刻で早い順に並ぶ（朝5時が昼1時より上）" do
    diary = user.diaries.create!(diary_on: Date.new(2026, 11, 17))
    diary.diary_plans.create!(starts_at: "13:00", ends_at: "15:00", window: window)
    diary.diary_plans.create!(starts_at: "05:00", ends_at: "06:30", window: window)
    diary.reload.build_blank_plans
    expect(diary.sorted_plans.map { |p| p.starts_at&.strftime("%H:%M") }).to eq([ "05:00", "13:00", nil, nil, nil ])
  end
end
