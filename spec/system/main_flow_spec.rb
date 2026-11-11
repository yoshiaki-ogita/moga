require "rails_helper"

# 主要機能の流れ（#32）。利用者が画面を順に操作する通りに確かめる
RSpec.describe "MOGA の主な流れ", type: :system do
  it "登録 → 大窓の名前 → 小窓 → 課題・記録の作成・編集・削除 → 進捗率が画面に出る → ログアウト・ログイン" do
    # 1. 登録すると Home に曼荼羅が出る
    visit new_user_path
    fill_in "user_name", with: "荻田"
    fill_in "user_email", with: "ogita@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    click_button "登録する"
    expect(page).to have_content("現在地：Home")
    expect(page).to have_content("全体の進捗率")
    expect(page).to have_link("局面A")

    # 2. 大窓の名前をつける
    click_link "局面A"
    click_link "この大窓の名前を直す"
    fill_in "phase_name", with: "社労士"
    click_button "保存する"
    expect(page).to have_content("A 社労士")

    # 3. 課題型の小窓を作り、課題を足す・済みにする・直す・消す
    click_link "＋ 小窓を作る", match: :first
    fill_in "window_title", with: "労働基準法"
    choose "課題型（済んだ課題 ÷ 課題）"
    click_button "保存する"
    click_link "労働基準法"
    fill_in "plan_title", with: "第1章"
    click_button "足す"
    fill_in "plan_title", with: "第2章"
    click_button "足す"
    expect(page).to have_content("まだ（2）")
    expect(page).to have_content("0 / 2")

    within("#plan_#{Plan.find_by(title: '第1章').id}") { click_button "済み" }
    expect(page).to have_content("済み（1）")
    expect(page).to have_content("50%")
    expect(page).to have_content("1 / 2")

    within("#plan_#{Plan.find_by(title: '第2章').id}") { click_link "直す" }
    fill_in "plan_title", with: "第2章 労働時間"
    click_button "保存する"
    expect(page).to have_content("第2章 労働時間")

    deleted_id = Plan.find_by(title: "第2章 労働時間").id
    within("#plan_#{deleted_id}") { click_button "消す" }
    expect(page).not_to have_css("#plan_#{deleted_id}")
    expect(page).to have_content("100%")

    # 4. 達成率型の小窓を作り、記録を書く・直す・消す
    click_link "A 社労士"
    click_link "＋ 小窓を作る", match: :first
    fill_in "window_title", with: "過去問"
    choose "達成率型（できた数 ÷ やった数）"
    click_button "保存する"
    click_link "過去問"
    fill_in "entry_attempted_count", with: "20"
    fill_in "entry_achieved_count", with: "16"
    click_button "記録する"
    fill_in "entry_attempted_count", with: "10"
    fill_in "entry_achieved_count", with: "10"
    click_button "記録する"
    expect(page).to have_content("これまでの記録（2）")
    expect(page).to have_content("26 / 30")
    expect(page).to have_content("87%")

    first(:link, "直す", href: %r{/entries/}).click
    fill_in "entry_achieved_count", with: "8"
    click_button "保存する"
    expect(page).to have_content("24 / 30") # 上の行（あとで書いた 10問中10問）を 8 に直した

    first(:button, "消す").click
    expect(page).to have_content("これまでの記録（1）")

    # 5. 大窓と Home にも、進捗率が出る（大窓 = 小窓の平均）
    click_link "A 社労士"
    expect(page).to have_content("小窓 2 個の平均")

    # 6. ログアウトして、もう一度ログインできる
    click_link "Home"
    click_button "ログアウト"
    visit login_path
    fill_in "メールアドレス", with: "ogita@example.com"
    fill_in "パスワード", with: "password123"
    click_button "ログインする"
    expect(page).to have_content("A")
    expect(page).to have_content("社労士")
  end

  it "他人の小窓・課題・記録は見られない・変えられない" do
    other = create(:user)
    other_window = other.phases.find_by(code: "A").windows.create!(number: 1, title: "他人の窓", measure: :plan_count)
    other_plan = other_window.plans.create!(title: "他人の課題")
    other_entry = other.phases.find_by(code: "A").windows.create!(number: 2, title: "他人の記録窓", measure: :achievement_rate)
                       .entries.create!(recorded_on: Date.current, attempted_count: 1, achieved_count: 1)

    me = create(:user, password: "password123")
    visit login_path
    fill_in "メールアドレス", with: me.email
    fill_in "パスワード", with: "password123"
    click_button "ログインする"

    [ window_path(other_window), edit_plan_path(other_plan), edit_entry_path(other_entry), phase_path(other_window.phase) ].each do |path|
      visit path
      expect(page.status_code).to eq(404)
    end
  end
end
