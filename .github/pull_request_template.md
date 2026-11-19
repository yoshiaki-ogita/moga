<!--
  PR の書式（型紙）です。新しい PR を作ると、この見出しが本文に最初から入ります。
  役所の申請書と同じで、欄を埋めれば書き忘れが起きません。
  （この囲みの中の文は、GitHub の画面には表示されないメモです）
-->

## 紐づく Issue（課題札）

Closes #

<!-- 「Closes #番号」と書くと、この PR をマージした時にその Issue が自動で閉じます（運営事務局からの課題 #9）。 -->

## なぜ直すのか

<!-- 困っていたこと・直す理由を、あとで読み返して分かるように書きます（課題 #14）。 -->

## 何をしたか

-

## 確かめたこと

- [ ] CI（scan_ruby / scan_js / lint / test）がすべて通った
- [ ] 本番で画面を見て確かめた（画面が変わる PR のとき）

## 題とコミットの頭文字

- [ ] PR の題とコミットの頭に `feat:` `fix:` `refactor:` `test:` `docs:` `chore:` のどれかを付けた（課題 #10。意味は [.github/commit_convention.md](https://github.com/yoshiaki-ogita/moga/blob/main/.github/commit_convention.md)）
- [ ] コミットを「1つの意味ごとに1回」に分けた（目安は 1PR あたり2〜10回。課題 #11）
