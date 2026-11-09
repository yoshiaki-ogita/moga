require "rails_helper"

RSpec.describe Phase, type: :model do
  let(:user) { create(:user) }

  it "利用者を登録すると、大窓 A〜H が「局面A」〜「局面H」の名前で8つできる" do
    expect(user.phases.order(:code).pluck(:code, :name)).to eq(
      Phase::CODES.map { |code| [ code, "局面#{code}" ] }
    )
  end

  it "ensure_default_phases を何度呼んでも、大窓は8つより増えない" do
    user.ensure_default_phases
    expect(user.phases.count).to eq(8)
  end

  it "同じ利用者に同じ記号の大窓は作れない" do
    phase = user.phases.build(code: "A", name: "もう1つのA")
    expect(phase).not_to be_valid
  end

  it "記号は A〜H だけ" do
    phase = user.phases.build(code: "Z", name: "Z")
    expect(phase).not_to be_valid
  end

  it "大窓の名前が空ならエラー" do
    phase = user.phases.find_by(code: "A")
    phase.name = ""
    expect(phase).not_to be_valid
  end

  it "利用者を消すと、大窓も一緒に消える" do
    user
    expect { user.destroy }.to change(Phase, :count).by(-8)
  end
end
