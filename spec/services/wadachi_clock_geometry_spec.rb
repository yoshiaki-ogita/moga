require "rails_helper"

# わたしの轍の時計の「計算の係」のテスト（絵を描かずに、計算だけを確かめる）
RSpec.describe WadachiClockGeometry do
  let(:t) { ->(s) { Time.zone.parse("2000-01-01 #{s}") } }

  describe ".point（時間 → 円の上の点）" do
    it "真上が0時、右回りに6時・12時・18時" do
      expect(described_class.point(0, 100)).to eq([ 210.0, 110.0 ])
      expect(described_class.point(6, 100)).to eq([ 310.0, 210.0 ])
      expect(described_class.point(12, 100)).to eq([ 210.0, 310.0 ])
      expect(described_class.point(18, 100)).to eq([ 110.0, 210.0 ])
    end
  end

  describe ".hours_of / .mid_hour" do
    it "7時30分は7.5時間、7時30分〜10時の真ん中は8.75時" do
      expect(described_class.hours_of(t["07:30"])).to eq(7.5)
      expect(described_class.mid_hour(t["07:30"], t["10:00"])).to eq(8.75)
    end
  end

  describe ".arc_path（扇形の道筋）" do
    it "外の弧を進み、内の弧を戻って閉じる（Z）" do
      d = described_class.arc_path(t["07:30"], t["10:00"], 130, 170)
      expect(d).to eq("M367.1,275.1 A170,170 0 0 1 295.0,357.2 L275.0,322.6 A130,130 0 0 0 330.1,259.7 Z")
    end

    it "12時間を超える扇形は、大きい弧の印（1）が付く" do
      d = described_class.arc_path(t["06:00"], t["20:00"], 130, 170)
      expect(d).to include("A170,170 0 1 1", "A130,130 0 1 0")
    end
  end

  describe ".hours_label（合計）" do
    it "「7時間」「6.5時間」の形。いくつかの時間帯を足す" do
      expect(described_class.hours_label([ [ t["05:00"], t["12:00"] ] ])).to eq("7時間")
      expect(described_class.hours_label([ [ t["05:00"], t["06:30"] ], [ t["20:00"], t["21:00"] ] ])).to eq("2.5時間")
      expect(described_class.hours_label([])).to eq("0時間")
    end
  end

  describe ".tint（色を淡くする）" do
    it "白へ45%混ぜる。0%ならそのまま、100%なら白" do
      expect(described_class.tint("#1e88e5", 0.45)).to eq("#83bef1")
      expect(described_class.tint("#1e88e5", 0)).to eq("#1e88e5")
      expect(described_class.tint("#1e88e5", 1)).to eq("#ffffff")
    end
  end
end
