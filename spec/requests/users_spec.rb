require "rails_helper"

RSpec.describe "Users（ユーザー登録）", type: :request do
  describe "GET /users/new" do
    it "登録画面が表示される" do
      get new_user_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ユーザー登録")
    end

    it "パスワードの欄に長い合言葉のお勧めが出る（守り6）" do
      get new_user_path
      expect(response.body).to include("16文字ほどの長い合言葉がお勧めです", "ほかの場所と同じパスワードは使わないでください")
    end
  end

  describe "POST /users" do
    let(:valid_params) do
      { user: { name: "moga太郎", email: "taro@example.com",
                password: "password123", password_confirmation: "password123" } }
    end

    it "正しく入力すると登録され、ログイン状態で Home へ進む" do
      expect { post users_path, params: valid_params }.to change(User, :count).by(1)
      expect(response).to redirect_to(home_path)
      follow_redirect!
      expect(response.body).to include("moga太郎").and include("局面A")
    end

    it "同じメールアドレスでは登録できない" do
      create(:user, email: "taro@example.com")
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

    it "注意を受けた欄も箱（field_with_errors）で包まれず、他の欄と同じ幅のまま（#107）" do
      valid_params[:user][:name] = ""
      post users_path, params: valid_params
      expect(response.body).to include("名前を入力してください")
      expect(response.body).not_to include("field_with_errors")
    end
  end
end
