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
今回採用したTypeScript関連の技術スタックの経験は、フロント側はあっても、バックエンド側は業務で利用したことはなく、勘で書いてる感じです😇
変なこと言ってたら、椅子を投げてください。

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

Webアプリケーションのテンプレートは、TSX以外で書きたくないと思えるくらい体験が良いと思います。
加えて、今回の要件的に、スケールのことは考えなくて良く、言語切り替えの認知負荷を下げたいので、
フロントエンド、バックエンド両方ともTypeScriptで書いてみようと思いました。

一休さん、トグルさん、ピクスタさんの採用事例みて、共感する部分も多かったです。
https://speakerdeck.com/yasaichi/architecture-decision-for-the-next-10-years-at-pixta
https://speakerdeck.com/naoya/typescript-guan-shu-xing-sutairudebatukuendokai-fa-noriaru
https://speakerdeck.com/susan1129/honoxdedong-kasuapurikesiyonnoriaru

### Bun

TypeScriptを処理するのに何が良いか考えると、denoも惹かれましたが、Bunには何でも入っている感じがしたので採用しました。
ビルドツール、SQLiteのドライバー、テスティングフレームワークなどなど入っていて、異常な気合いを感じます。
もし問題があっても代替手段がありそうなので、気軽に採用しています。

### Hono と HonoX

@yusukebeさんが書いてるフレームワークなので、以前からhonoのことは知っていて、ずっと使う機会を伺っていました。
(調べるとhonoのinitial commitから2.5ヶ月後のYAPCで登壇されていたようです
https://x.com/yusukebe/status/1499989656124858373 )

なので、honoは面白そうという気持ちで選んでます。
ソースコード込みで、コアがシンプルですし、Web標準に沿ってるので、運用はどうにでもなりそうな感じがしてます。
honoxは、楽して開発を始められそうだからと使い始めました。

### SQLite

SQLiteならデータは一枚のファイルに収まるので、データを管理、所持する要件に手軽に合いそうです。
Obsidianのようにメモごとにファイルを用意するのもシンプルな構成で理にかなってると思いますが、
少なくともTODOアプリ作るなら、SQLiteで十分だと思います。

### Drizzle ORM

Prizma と Bunのsqlで悩みました。
SQLの実行計画が想像しにくいと、

