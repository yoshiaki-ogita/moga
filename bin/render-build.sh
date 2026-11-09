#!/usr/bin/env bash
# Render で公開するときの組み立て手順（Render の公式ガイド「Deploy Rails 8」と同じ形）
# 1. 部品をそろえる → 2. 画面の見た目（CSS・JS）を用意する → 3. 帳簿（Neon）に表を作る
set -o errexit

bundle install
bin/rails assets:precompile
bin/rails assets:clean
bin/rails db:migrate
