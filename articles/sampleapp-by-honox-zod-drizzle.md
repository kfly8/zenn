---
title: ""
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

## はじめに

次の3つの要件を満たす社内向けWebアプリケーションを作るにあたり、[サンプルのTODOアプリケーションを作成した](https://github.com/kfly8/sample-todoapp-honox-zod-drizzle)ので、その紹介と感想を書きます。

1. セルフホストが簡単。特にデータは、自身で管理、所持できる
2. ソースを公開した際に、改変がしやすそうな技術スタックを利用したい。できれば、なんか面白そうなのがいい
3. 開発チームは私ひとり。企画も営業も私。認知負荷は下げたい。

筆者自身は、ISUCON10,11,12,13でPerlへの移植作業をしたり、[YAPC::Hiroshima 2024](https://yapcjapan.org/2024hiroshima/) の運営だったりと、Perlで生活しています。
今回採用したTypeScrip関連の技術スタックの経験は、フロント側を書くことはあっても、バックエンド側は業務で利用したことはなく、勘で書いてる感じです😅
変なこと言ってたら、椅子を投げてください！

## 採用した技術スタックとその採用理由

結果的には、次の技術スタックを利用してみました。

- Language / Runtime
    - TypeScript
    - [Bun](https://bun.sh/)
- Web Application Framework
    - [Hono](https://hono.dev/) + [honox](https://github.com/honojs/honox)
- Database / ORM
    - [SQLite](https://www.sqlite.org/)
    - [drizzle](https://orm.drizzle.team/)
- Validation, Data Modeling
    - [Zod](https://zod.dev/)
- misc
    - [Bun test](https://bun.sh/docs/cli/test)
    - [Tailwind CSS](https://tailwindcss.com/)
    - [neverthrow](https://github.com/supermacro/neverthrow)
        - Result type for TypeScript / To Handle expected errors

### TypeScript

Webアプリケーションのフロントエンドを書く時、TSX以外で書きたくないと思えるくらい良いと思います。
加えて、今回の要件的に、スケールのことは考えなくて良く、言語切り替えの認知負荷を下げたいので、
バックエンドもTypeScriptで書いてみようと思いました。

一休さん、トグルさん、ピクスタさんの採用事例みて、共感する部分も多かったですし。
https://speakerdeck.com/yasaichi/architecture-decision-for-the-next-10-years-at-pixta
https://speakerdeck.com/naoya/typescript-guan-shu-xing-sutairudebatukuendokai-fa-noriaru
https://speakerdeck.com/susan1129/honoxdedong-kasuapurikesiyonnoriaru

### Bun

TypeScriptを処理するのに何が良いか考えると、denoも惹かれたけれど、Bunには何でも入っている感じがしたので採用しました。
ビルドツール、SQLiteのドライバー、テスティングフレームワークも入ったりして、異常な気合いですごいと思いました。
もし問題があっても代替手段がありそうなので、気軽に採用しています。

### Hono と HonoX

@yusukebeさんが書いてるフレームワークなので、もちろん以前からhonoは知っていて、ずっと使う機会を伺っていた。
(調べるとhonoのinitial commitから2.5ヶ月後のYAPCで登壇されていた! )
https://x.com/yusukebe/status/1499989656124858373

honoはWeb標準に沿っているので、もしセルフホストだけでなく、クラウドサービスを提供したいとなっても運用の選択肢が多いなぁと。
そして、コアがシンプルなので、やりたい構成が出てきた時にどうにかなる感じがして嬉しい。
ただ、honoの型周りのコードは雰囲気でしか読めてない。実装より三段くらい難易度高い感じて、たとえばこの辺(todo)とか、全くわからない。
アプリケーション側の開発をする分には問題なくむしろ恩恵に預かれていて感謝。

honoxは、楽して開発を始められそうだからと使い始めた。

### SQLite

セルフホストした人がデータを管理、所持できるようにするなら、



