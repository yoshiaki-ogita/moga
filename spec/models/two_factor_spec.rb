require "rails_helper"

# 二段の鍵（守り2）の土台：種を作る・6桁を確かめる・使い始める・やめる
RSpec.describe TwoFactor, type: :model do
  let(:user) { create(:user, email: "hanako@example.com") }

  # スマホのアプリの代わりに、同じ種から6桁を出す
  def code_for(user, at: Time.current)
    ROTP::TOTP.new(user.otp_secret).at(at)
  end

  describe "#prepare_otp!" do
    it "新しい種を作るが、まだ二段の鍵は効かない" do
      expect(user.prepare_otp!).to be true
      expect(user.otp_secret).to be_present
      expect(user.otp_enabled?).to be false
    end

    it "お試しの見本の利用者は、二段の鍵を使えない" do
      demo = DemoAccount.prepare!
      expect(demo.prepare_otp!).to be false
      expect(demo.reload.otp_secret).to be_nil
    end
  end

  describe "#otp_provisioning_uri" do
    it "スマホのアプリに渡す文字列に、MOGA とメールアドレスが入る" do
      user.prepare_otp!
      uri = user.otp_provisioning_uri
      expect(uri).to start_with("otpauth://totp/")
      expect(uri).to include("issuer=MOGA")
      expect(uri).to include("hanako%40example.com")
    end

    it "種がなければ何も返さない" do
      expect(user.otp_provisioning_uri).to be_nil
    end
  end

  describe "#enable_otp!" do
    before { user.prepare_otp! }

    it "正しい6桁で、二段の鍵を使い始める" do
      expect(user.enable_otp!(code_for(user))).to be true
      expect(user.reload.otp_enabled?).to be true
    end

    it "違う6桁では使い始めない" do
      wrong = code_for(user) == "000000" ? "111111" : "000000"
      expect(user.enable_otp!(wrong)).to be false
      expect(user.reload.otp_enabled?).to be false
    end
  end

  describe "#verify_otp" do
    # 使い始めてから1分たった所で確かめる（使い始めの6桁と重ならないように）
    before do
      user.prepare_otp!
      user.enable_otp!(code_for(user))
      travel 1.minute
    end

    after { travel_back }

    it "今の6桁なら通る" do
      expect(user.verify_otp(code_for(user))).to be true
    end

    it "全角の数字や、間の空白も受け付ける" do
      code = code_for(user)
      zenkaku = code.tr("0-9", "０-９").insert(3, " ")
      expect(user.verify_otp(zenkaku)).to be true
    end

    it "同じ6桁は2回使えない（盗み見た数字の使い回しを止める）" do
      code = code_for(user)
      expect(user.verify_otp(code)).to be true
      expect(user.verify_otp(code)).to be false
    end

    it "スマホの時計が少し遅れていても、30秒前の数字までは通る" do
      expect(user.verify_otp(code_for(user, at: 30.seconds.ago))).to be true
    end

    it "1分前の古い数字は通らない" do
      expect(user.verify_otp(code_for(user, at: 1.minute.ago))).to be false
    end

    it "6桁でない・数字でないものは通らない" do
      expect(user.verify_otp("12345")).to be false
      expect(user.verify_otp("abcdef")).to be false
      expect(user.verify_otp(nil)).to be false
    end
  end

  describe "#disable_otp!" do
    # 使い始めてから1分たった所で確かめる（使い始めの6桁と重ならないように）
    before do
      user.prepare_otp!
      user.enable_otp!(code_for(user))
      travel 1.minute
    end

    after { travel_back }

    it "パスワードと6桁の両方が合えば、やめられる（種も消える）" do
      expect(user.disable_otp!(password: "password123", code: code_for(user))).to be true
      user.reload
      expect(user.otp_enabled?).to be false
      expect(user.otp_secret).to be_nil
    end

    it "パスワードが違えば、やめられない" do
      expect(user.disable_otp!(password: "wrong-password", code: code_for(user))).to be false
      expect(user.reload.otp_enabled?).to be true
    end

    it "6桁が違えば、やめられない" do
      expect(user.disable_otp!(password: "password123", code: "12345")).to be false
      expect(user.reload.otp_enabled?).to be true
    end
  end

  it "二段の鍵を使わない人は、これまでどおり（何も変わらない）" do
    expect(user.otp_enabled?).to be false
    expect(user.verify_otp("123456")).to be false
  end
end

RSpec.describe "予備の鍵（守り2 ②）", type: :model do
  let(:user) { create(:user) }

  it "16個作り、鍵そのものは保存しない（指紋だけ）" do
    codes = user.regenerate_backup_codes!
    expect(codes.size).to eq(16)
    expect(codes.uniq.size).to eq(16)
    expect(codes).to all(match(/\A[a-z2-9]{5}-[a-z2-9]{5}\z/))
    expect(OtpBackupCode.where(user: user).pluck(:code_digest)).not_to include(*codes)
  end

  it "1つの鍵は1回だけ使える" do
    code = user.regenerate_backup_codes!.first
    expect(user.consume_backup_code!(code)).to be true
    expect(user.consume_backup_code!(code)).to be false
    expect(user.remaining_backup_codes_count).to eq(15)
  end

  it "全角・大文字・ハイフン抜きでも同じ鍵とみなす" do
    code = user.regenerate_backup_codes!.first
    typed = code.delete("-").upcase.tr("A-Z0-9", "Ａ-Ｚ０-９")
    expect(user.consume_backup_code!(typed)).to be true
  end

  it "作り直すと、前の16個は使えなくなる" do
    old_code = user.regenerate_backup_codes!.first
    user.regenerate_backup_codes!
    expect(user.consume_backup_code!(old_code)).to be false
    expect(user.remaining_backup_codes_count).to eq(16)
  end

  it "ほかの人の予備の鍵は使えない" do
    other_code = create(:user).regenerate_backup_codes!.first
    expect(user.consume_backup_code!(other_code)).to be false
  end

  it "二段の鍵をやめると、予備の鍵も消える" do
    user.prepare_otp!
    user.enable_otp!(ROTP::TOTP.new(user.otp_secret).now)
    user.regenerate_backup_codes!
    travel 1.minute do
      user.disable_otp!(password: "password123", code: ROTP::TOTP.new(user.otp_secret).now)
    end
    expect(user.otp_backup_codes.count).to eq(0)
  end
end
