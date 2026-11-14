require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "名前・メール・パスワードがそろっていれば有効" do
      expect(build(:user)).to be_valid
    end

    it "名前が空ならエラー" do
      user = build(:user, name: "")
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("を入力してください")
    end

    it "メールアドレスが空ならエラー" do
      user = build(:user, email: "")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("を入力してください")
    end

    it "メールアドレスが重複していたらエラー（大文字・小文字の違いも同じとみなす）" do
      create(:user, email: "ogita@example.com")
      user = build(:user, email: "OGITA@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("は使用できません")
    end

    it "パスワードが空ならエラー" do
      user = build(:user, password: "", password_confirmation: "")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("を入力してください")
    end
  end

  describe "パスワード" do
    let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

    it "正しいパスワードなら authenticate できる" do
      expect(user.authenticate("password123")).to eq(user)
    end

    it "違うパスワードでは authenticate できない" do
      expect(user.authenticate("wrong-pass")).to be false
    end

    it "パスワードはそのまま保存されず、ハッシュ化される" do
      expect(user.password_digest).not_to eq("password123")
    end
  end

  describe "メールアドレスの保存" do
    it "小文字にそろえて保存される" do
      user = create(:user, email: "Ogita@Example.COM")
      expect(user.reload.email).to eq("ogita@example.com")
    end
  end
end
