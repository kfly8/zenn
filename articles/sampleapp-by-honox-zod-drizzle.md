---
title: "HonoXでTodoアプリを作った感想"
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

## はじめに

次の3つの要件を満たす社内向けWebアプリケーションを作るにあたり、[サンプルのTODOアプリケーションを作成した](https://github.com/kfly8/sample-todoapp-honox-zod-drizzle)ので、その感想を書きます。

1. セルフホストが簡単。特にデータは、自身で管理、所持できる
2. ソース公開した時に、触りやすい技術スタックだと嬉しい。
3. 開発チームは私ひとり。企画も営業も私。認知負荷は下げたい。

筆者自身は、ISUCON10,11,12,13でPerlへの移植作業をしたり、[YAPC::Hiroshima 2024](https://yapcjapan.org/2024hiroshima/) の運営だったりと、Perlで生活しています。
今回採用したTypeScript関連の経験は、フロント側はあっても、バックエンド側は皆無で、勘で書いてる感じです。変なこと言ってたら、椅子を投げてください！

## 採用した技術スタックとその採用理由

要件踏まえて、結果的には、次の技術スタックを利用してます

- Language / Runtime
    - TypeScript
    - [Bun v1.2](https://bun.sh/)
- Web Application Framework
    - [Hono](https://hono.dev/)
    - [honox](https://github.com/honojs/honox)
- Database / ORM
    - [SQLite](https://www.sqlite.org/)
    - [drizzle](https://orm.drizzle.team/)
- Validation, Domain Modeling
    - [Zod](https://zod.dev/)
- misc
    - [neverthrow](https://github.com/supermacro/neverthrow)
    - [tailwindcss v4](https://tailwindcss.com/)

### TypeScript と Bun

Webアプリケーションのビューは、TSX以外で書きたくないと思えるくらい体験に違いがあると思っています。
加えて、今回の要件的に、スケールのことは考えなくて良く、言語切り替えの認知負荷を下げたいので、フロントエンド、バックエンド両方ともTypeScriptで書いてみようと思いました。

一休さん、Toggleさん、ピクスタさんの採用事例に影響を受けています！
- https://speakerdeck.com/naoya/typescript-guan-shu-xing-sutairudebatukuendokai-fa-noriaru
- https://speakerdeck.com/susan1129/honoxdedong-kasuapurikesiyonnoriaru
- https://speakerdeck.com/yasaichi/architecture-decision-for-the-next-10-years-at-pixta

また、TypeScriptを処理するのにBunを選びました。Bunには何でも入っていて、一人開発の負担を減らせそうです。例えば、テスティングフレームワークがバンドルされていて、jestっぽく書けて、超高速です。
[最近、1.2が出ていました](https://bun.sh/blog/bun-v1.2)が、異常な気合いで何でも入ってる感じがします。

### Hono と HonoX

Honoはずっと使う機会を伺っていました。正直、Hono 面白そう！という気持ちで選んでます。

調べてみると、Honoの最初のコミットをして2.5ヶ月後に、Honoに関するトークをYAPCでしていたようです。
https://x.com/yusukebe/status/1499989656124858373 

Honoのアプリケーションはあまり書いたことなかったですが、[HonoをPerlに移植するPono](https://github.com/kfly8/pono)を細々と書いていて、ソースコードはなぜか読んでいる状況で、書く機会が巡ってきて嬉しいです。
Honoはソースコード込みで、コアがシンプルで、Web標準にも沿っているので、運用はどうにでもなりそうな感じがして好きです。
（型関連のコードは実装より三段くらい難しい印象で、勘で読んでますが！）

HonoXは、Vite周りの設定を省略して開発を始められそうなことと、ファイルベースルーティングで単調なつくりにしやすそうなので選びました。

### その他

- SQLite
    - SQLiteならデータは一枚のファイルに収まるので、データを管理、所持する要件にお手軽に合いそうです。
- Drizzle ORM
    - SQLの実行計画が想像しやすく、型によるサポートが強そうなので選びました。
- Zod
    - 他を知らないので、積極的な理由はなく、馴染みがあったので選んでます。
    - 普段、Perlの型制約ライブラリのType::Tinyを使い倒しているのですが、それと似た感覚で使ってます。[ZodをPerlに移植するPoz](https://metacpan.org/pod/Poz)を読んでいた影響もあります。
    - 詳しくは後述しますが、ドメインモデリングもZodに大半を任せる設計にしました。
- neverthrow
    - TypeScriptにresult型を提供するモジュールです。想定内のエラーは型情報に現れた方がハンドリング漏れしないので利用してます。
- tailwindcss v4
    - [ここ数年のYAPCのLPが、tailwindcssで作られていて](https://yapcjapan.org)、馴染みがあるくらいの理由です。最近出たv4にしても、すんなり動いてます。

## 採用された設計

設計は、ソース公開と認知負荷を踏まえ、次を意識して組み立ててます。

1. ドメインはドメインに集中して、インフラの知識は別問題として切り離したい。逆も然り。
2. 単調な作りにしたい。単純過ぎてあくびが出る感じの作りがいい。

1のことから、依存の逆転はした方が良く

```bash
app
├── client.ts
├── cmd
│   ├── CreateTodoCmd.test.ts
│   ├── CreateTodoCmd.ts
│   ├── UpdateTodoCmd.test.ts
│   └── UpdateTodoCmd.ts
├── domain
│   ├── todo.ts
│   ├── todoService.test.ts
│   └── todoService.ts
├── infra
│   ├── CreateTodoRepository.test.ts
│   ├── CreateTodoRepository.ts
│   ├── UpdateTodoRepository.test.ts
│   ├── UpdateTodoRepository.ts
│   ├── index.ts
│   ├── schema.ts
│   └── types.ts
├── islands
│   ├── HeaderIsland
│   └── TodoIsland
├── routes
│   ├── _404.tsx
│   ├── _error.tsx
│   ├── _middleware.ts
│   ├── _renderer.tsx
│   ├── api
│   └── index.tsx
├── server.ts
└── style.css
```
