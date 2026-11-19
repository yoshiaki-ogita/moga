# ログイン前に見るページ（TOPページなど）
class StaticPagesController < ApplicationController
  def top; end

  # 使い方の画面（#115）。README ではなく、使う人向けの取扱説明書をアプリの中に置く（2026-11-15・16 作者の決定）
  def guide; end
end
