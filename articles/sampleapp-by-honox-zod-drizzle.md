---
title: ""
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

## はじめに

次の要件を満たす社内ツールを作るにあたり、[サンプルのTODOアプリケーションを作成した](https://github.com/kfly8/sample-todoapp-honox-zod-drizzle)ので、その紹介および感想を書きます。

1. セルフホストが簡単で、特にデータは、自身で管理、所持できる
2. ソースを公開した際に、改変がしやすそうな技術スタックを利用したい。できたら面白そうなのがいい

筆者自身は、Perlの経験が長く、シンプルな、[YAPC::Hiroshima 2024](https://yapcjapan.org/2024hiroshima/) の主催だったりをしています。

## 採用した技術スタックとその採用理由

結果的には、次の技術スタックを利用しました。

- Runtime
    - [Bun](https://bun.sh/)
- Web Application Framework
    - [Hono](https://hono.dev/) + [honox](https://github.com/honojs/honox)
- Database, ORM
    - [SQLite](https://www.sqlite.org/)
    - [drizzle](https://orm.drizzle.team/)
- Validation, Data Modeling
    - [Zod](https://zod.dev/)
- misc
    - [Bun test](https://bun.sh/docs/cli/test)
    - [Tailwind CSS](https://tailwindcss.com/)
    - [neverthrow](https://github.com/supermacro/neverthrow)
        - Result type for TypeScript / To Handle expected errors

### Bun

## 
