require "rails_helper"

RSpec.describe "StaticPages", type: :request do
  describe "GET /" do
    it "TOPページが表示される" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("育てられる記録")
    end

    it "キャッチフレーズ・曼荼羅の見本・3つの歩みが表示される" do
      get root_path
      expect(response.body).to include("MOGAの⚪︎は、あなた自身です。")
      expect(response.body).to include("曼荼羅の見本")
      expect(response.body).to include("毎日、課題と記録を1行残す")
    end
  end
end
