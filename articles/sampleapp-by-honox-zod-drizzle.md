---
title: ""
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: []
published: false
---

## はじめに

次の要件を満たす社内向けWebアプリケーションを作るにあたり、[サンプルのTODOアプリケーションを作成した](https://github.com/kfly8/sample-todoapp-honox-zod-drizzle)ので、その紹介と感想を書きます。

1. セルフホストが簡単。特にデータは、自身で管理、所持できる
2. ソースを公開した際に、改変がしやすそうな技術スタックを利用したい。できたら面白そうなのがいい
3. 開発チームは私ひとり。

筆者自身は、ISUCON10,11,12,13でPerlへの移植作業をしたり、[YAPC::Hiroshima 2024](https://yapcjapan.org/2024hiroshima/) の主催だったりと、Perlで生活しています。
フロント側でTypeScriptを書くことはあっても、バックエンドのTypeScript関連の技術スタックは業務で利用したことはなく、勘で書いてる感じです。運用した時にどうなるかはまだ謎です。

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

フロントエンドを書く時、エコシステムの豊富さ、開発体験の都合、JSX以外の選択肢はないと思い、私一人で開発するなら、バックエンドもTypeScriptで書いてみようと思いました。
https://speakerdeck.com/susan1129/honoxdedong-kasuapurikesiyonnoriaru
