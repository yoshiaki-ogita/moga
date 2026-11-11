require "rails_helper"

# 進捗率の計算（#28）。例の数字どおりの％になるかを確かめる
RSpec.describe "進捗率の計算（#28）", type: :model do
  let(:user) { create(:user) }
  let(:phase_a) { user.phases.find_by(code: "A") }

  describe "小窓（Window）" do
    it "課題型：済んだ課題 ÷ 課題（4つ中1つ済み → 25%）" do
      window = phase_a.windows.create!(number: 1, title: "労働基準法", measure: :plan_count)
      window.plans.create!(title: "第1章", done_at: Time.current)
      3.times { |i| window.plans.create!(title: "第#{i + 2}章") }
      expect(window.progress_fraction).to eq([ 1, 4 ])
      expect(window.progress_percent).to eq(25)
    end

    it "達成率型：できた数の合計 ÷ やった数の合計（16/20 と 10/10 → 26÷30＝87%）" do
      window = phase_a.windows.create!(number: 2, title: "過去問", measure: :achievement_rate)
      window.entries.create!(recorded_on: Date.current, attempted_count: 20, achieved_count: 16)
      window.entries.create!(recorded_on: Date.current, attempted_count: 10, achieved_count: 10)
      expect(window.progress_fraction).to eq([ 26, 30 ])
      expect(window.progress_percent).to eq(87)
    end

    it "課題も記録も0件の窓は 0%（講師補足①）" do
      plan_window = phase_a.windows.create!(number: 3, title: "空の課題型", measure: :plan_count)
      rate_window = phase_a.windows.create!(number: 4, title: "空の達成率型", measure: :achievement_rate)
      expect(plan_window.progress_percent).to eq(0)
      expect(rate_window.progress_percent).to eq(0)
    end

    it "全部済めば 100%" do
      window = phase_a.windows.create!(number: 5, title: "全部済み", measure: :plan_count)
      window.plans.create!(title: "1つだけ", done_at: Time.current)
      expect(window.progress_percent).to eq(100)
    end
  end

  describe "大窓（Phase）" do
    it "中の小窓の平均（25% と 75% → 50%）" do
      w1 = phase_a.windows.create!(number: 1, title: "窓1", measure: :plan_count)
      w1.plans.create!(title: "済み", done_at: Time.current)
      3.times { |i| w1.plans.create!(title: "まだ#{i}") }
      w2 = phase_a.windows.create!(number: 2, title: "窓2", measure: :achievement_rate)
      w2.entries.create!(recorded_on: Date.current, attempted_count: 4, achieved_count: 3)
      expect(phase_a.reload.progress_percent).to eq(50)
    end

    it "小窓が1つもない大窓は 0%" do
      expect(phase_a.progress_percent).to eq(0)
    end
  end

  describe "全体（User）" do
    it "大窓 A〜H の平均（A だけ 80%、ほかは 0% → 10%）" do
      window = phase_a.windows.create!(number: 1, title: "窓1", measure: :achievement_rate)
      window.entries.create!(recorded_on: Date.current, attempted_count: 10, achieved_count: 8)
      expect(user.reload.progress_percent).to eq(10)
    end
  end
end

RSpec.describe "モデルに移した仕事（#35）", type: :model do
  let(:user) { create(:user) }
  let(:phase) { user.phases.find_by(code: "A") }

  it "User#mandala_phases は A〜H の大窓を記号で引ける形で返す" do
    expect(user.mandala_phases.keys).to match_array(Phase::CODES)
  end

  it "Phase#windows_by_number は小窓を番号で引ける形で返す" do
    phase.windows.create!(number: 3, title: "窓3")
    expect(phase.windows_by_number.keys).to eq([ 3 ])
  end

  it "Phase#default_window_number は、空いていればその番号、だめなら空いている一番小さい番号" do
    phase.windows.create!(number: 1, title: "窓1")
    expect(phase.default_window_number(5)).to eq(5)
    expect(phase.default_window_number(1)).to eq(2)
    expect(phase.default_window_number(0)).to eq(2)
  end

  it "Plan#done! と Plan#undone! で済んだ日時が入る・空になる" do
    plan = phase.windows.create!(number: 1, title: "窓1").plans.create!(title: "第1章")
    plan.done!
    expect(plan.reload).to be_done
    plan.undone!
    expect(plan.reload).not_to be_done
  end

  it "Entry#date_label は「11月10日」の形" do
    entry = Entry.new(recorded_on: Date.new(2026, 11, 10))
    expect(entry.date_label).to eq("11月10日")
  end
end
