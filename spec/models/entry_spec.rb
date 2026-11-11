require "rails_helper"

RSpec.describe Entry, type: :model do
  let(:window) { create(:user).phases.find_by(code: "A").windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate) }

  def build_entry(**attrs)
    window.entries.build({ recorded_on: Date.current, attempted_count: 20, achieved_count: 16 }.merge(attrs))
  end

  it "日付・やった数・できた数があれば保存できる（題名と本文はなくてよい）" do
    expect(build_entry).to be_valid
  end

  it "記録した日がないと保存できない" do
    expect(build_entry(recorded_on: nil)).not_to be_valid
  end

  it "やった数・できた数は0以上" do
    expect(build_entry(attempted_count: -1)).not_to be_valid
    expect(build_entry(achieved_count: -1)).not_to be_valid
  end

  it "できた数はやった数より多くできない" do
    entry = build_entry(attempted_count: 20, achieved_count: 21)
    expect(entry).not_to be_valid
    expect(entry.errors.full_messages).to include("できた数はやった数以下にしてください")
  end

  it "題名は50字まで、本文は1000字まで" do
    expect(build_entry(title: "あ" * 51)).not_to be_valid
    expect(build_entry(body: "あ" * 1001)).not_to be_valid
  end

  it "小窓を消すと記録も消える" do
    build_entry.save!
    expect { window.destroy }.to change(Entry, :count).by(-1)
  end
end
