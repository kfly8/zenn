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
2. ソースを公開しても誰でも改変がしやすそうな技術スタックを利用したい。できれば、なんか面白そうなのがいい
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
- Validation, Domain Modeling
    - [Zod](https://zod.dev/)
- misc
    - [neverthrow](https://github.com/supermacro/neverthrow)
        - Result type for TypeScript / To Handle expected errors

### TypeScript

Webアプリケーションのビューは、TSX以外で書きたくないと思えるくらい体験に違いがあると思っています。
加えて、今回の要件的に、スケールのことは考えなくて良く、言語切り替えの認知負荷を下げたいので、
フロントエンド、バックエンド両方ともTypeScriptで書いてみようと思いました。

一休さん、Toggleさん、ピクスタさんの採用事例みて、多分に影響を受けています。
- https://speakerdeck.com/naoya/typescript-guan-shu-xing-sutairudebatukuendokai-fa-noriaru
- https://speakerdeck.com/susan1129/honoxdedong-kasuapurikesiyonnoriaru
- https://speakerdeck.com/yasaichi/architecture-decision-for-the-next-10-years-at-pixta

### Bun

TypeScriptを処理するのにBunを選びました。Bunには何でも入っていて、一人開発の負担を減らせそうです。例えば、テスティングフレームワークがバンドルされていて、jestっぽく書けて、超高速です。最近、1.2が出ていましたが、異常な気合いで何でも入ってる感じがします。

### Hono と HonoX

Honoはずっと使う機会を伺っていました。正直、面白そう！という気持ちで選んでます。

@yusukebeさんが書いてるフレームワークなので以前からHonoのことは知っていて、
調べると、Honoのinitial commitから2.5ヶ月後のYAPCで登壇されていたようです。
https://x.com/yusukebe/status/1499989656124858373 

[HonoをPerlに移植するPono](https://github.com/kfly8/pono)を細々と書いてるのですが、
ソースコード混みで、コアがシンプルで、Web標準にも沿っているので、運用はどうにでもなりそうな感じがしてます。
（型関連のコードは雰囲気で読んでて、実装より三段くらい難しい印象を受けています）

HonoXは、Vite周りの設定を省略して開発を始められそうなので使い始めました。

### SQLite

SQLiteならデータは一枚のファイルに収まるので、データを管理、所持する要件にお手軽に合いそうです。

### Drizzle ORM

SQLの実行計画が想像しやすく、型によるサポートが強いものを選びました。

### Zod

他を知らないので、積極的な理由はなく、馴染みがあったので選んでます。

普段、Perlの型制約ライブラリのType::Tinyを使い倒しているのですが、それと似た感覚で使ってます。
[ZodをPerlに移植するPoz](https://metacpan.org/pod/Poz)を読んでいた影響もあります。

詳しくは後述しますが、ドメインモデリングもZodに大半を任せる設計にしました。

### neverthrow

想定してるエラーは、型情報に現れた方がハンドリング漏れしないので利用してます。

## 採用された設計

設計は、

1. ドメインはドメインに集中して、インフラの知識は別問題として切り離したい。逆も然り。
2. 単調な作りにしたい。単純過ぎてあくびが出る感じの作りがいい。

```bash
app
├── client.ts
├── cmd
│   ├── CreateTodoCmd.test.ts
│   ├── CreateTodoCmd.ts
│   ├── UpdateTodoCmd.test.ts
│   └── UpdateTodoCmd.ts
├── components
│   └── Layout.tsx
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
