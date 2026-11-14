require "rails_helper"

RSpec.describe "Users（ユーザー登録）", type: :request do
  describe "GET /users/new" do
    it "登録画面が表示される" do
      get new_user_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ユーザー登録")
    end
  end

  describe "POST /users" do
    let(:valid_params) do
      { user: { name: "荻田", email: "ogita@example.com",
                password: "password123", password_confirmation: "password123" } }
    end

    it "正しく入力すると登録され、ログイン状態で Home へ進む" do
      expect { post users_path, params: valid_params }.to change(User, :count).by(1)
      expect(response).to redirect_to(home_path)
      follow_redirect!
      expect(response.body).to include("荻田").and include("局面A")
    end

    it "同じメールアドレスでは登録できない" do
      create(:user, email: "ogita@example.com")
      expect { post users_path, params: valid_params }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("メールアドレスは使用できません")
      expect(response.body).not_to include("すでに使われています")
    end

    it "名前が空だと登録できない" do
      valid_params[:user][:name] = ""
      expect { post users_path, params: valid_params }.not_to change(User, :count)
      expect(response.body).to include("名前を入力してください")
    end
  end
end
