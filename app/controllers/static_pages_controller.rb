# ログイン前に見るページ（TOPページなど）
class StaticPagesController < ApplicationController
  def top; end

  # 使い方の画面（#115）。README ではなく、使う人向けの取扱説明書をアプリの中に置く（2026-11-15・16 作者の決定）
  def guide; end

  # 二段階認証の注意点だけの画面（2026-11-24 作者の決定）。始める前に、誰でも読めるようにする
  def two_factor_notice; end
end
