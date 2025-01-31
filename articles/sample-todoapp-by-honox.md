---
title: "HonoXでTodoアプリを作った感想"
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['hono','honox','zod','drizzle']
published: false
---

## はじめに

次の3つの要件を満たす社内向けWebアプリケーションを作るにあたり、[サンプルのTODOアプリケーションを作成した](https://github.com/kfly8/sample-todoapp-honox-zod-drizzle)ので、その感想を書きます。

- 要件1. セルフホストが簡単。特にデータは、自身で管理、所持できる
- 要件2. ソースを公開した時に、多くの人にとっつき易いと感じてもらえたら嬉しい
- 要件3. 開発チームは私ひとり。企画も営業も私。認知負荷は下げたい。

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

### TypeScript と Bun を選んだ理由

Webアプリケーションのビューは、TSX以外で書きたくないと思えるくらい他の言語と体験に違いがあると思っています。
加えて、今回の要件的に、スケールのことは考えなくて良く、言語切り替えの認知負荷を下げたいので、フロントエンド、バックエンド両方ともTypeScriptで書いてみようと思いました。

一休さん、Toggleさん、ピクスタさんの採用事例に影響を受けています！
- https://speakerdeck.com/naoya/typescript-guan-shu-xing-sutairudebatukuendokai-fa-noriaru
- https://speakerdeck.com/susan1129/honoxdedong-kasuapurikesiyonnoriaru
- https://speakerdeck.com/yasaichi/architecture-decision-for-the-next-10-years-at-pixta

また、TypeScriptを処理するのにBunを選びました。Bunには何でも入っていて、一人開発の負担を減らせそうです。例えば、テスティングフレームワークがバンドルされていて、超高速に動作するようです。[最近、1.2が出ていました](https://bun.sh/blog/bun-v1.2)が、異常な気合いで何でも入ってる感じがします。

### Hono と HonoX を選んだ理由

Honoを選んだ理由ですが、合理的な理由もありますが、Hono 面白そう！という気持ちが隠せないです。

調べてみると、yusukebeさんがHonoの最初のコミットをして2.5ヶ月後に、YAPCのトークがあったようです。それから、2年くらい経ってます。
https://x.com/yusukebe/status/1499989656124858373 

[HonoをPerlに移植するPono](https://github.com/kfly8/pono)を細々と書いていて、ソースコードはなぜか読んでました。
Honoはソースコード込みで、コアがシンプルで、Web標準にも沿っているので、運用はどうにでもなりそうな感じがして好きです。

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

蛇足ですが、ReactとNext.jsは採用していません。
Reactを利用しない積極的な理由はなく、hono/jsxでどこまでできるのか試してみたかったからです。表現したいUIやライブラリの対応状況次第では、Reactでレンダリングするように変更すると思います。
また、HonoXを利用すれば、Viteとの統合、ファイルベースルーティング、アイランドアーキテクチャはあるので、現時点でNext.jsを採用する理由が浮かんでいないです。

## 採用したアーキテクチャ

ただのTodoアプリですが、後々変更しやすいアプリケーションを作りたいので、ちょっと凝った作りにしています。例えば、こんなことを意識しています。

- ドメインはドメインに集中して、インフラの知識は別問題として切り離したい。逆も然り。
- 単純過ぎてあくびが出るくらい単調な作りにしたい。

こちらを踏まえて、依存の逆転、コマンドパターンなどを利用しています。以下、具体的にみていきたいと思います。

### ディレクトリ構成

ディレクトリは次のような構成になっています。それぞれ簡単に説明します。

```bash
app
├── client.ts                         ... HonoX標準のクライアントのエントリーポイント
├── server.ts                         ... HonoX標準のサーバーのエントリーポイント
├── style.css                         ... tailwindcssのエントリーポイント
│
├── cmd                               ... コマンドパターンの実装
│   ├── CreateTodoCmd.ts              ... e.g. Todo作成のコマンド、永続化を行うRepositoryの定義も含む
│   └── UpdateTodoCmd.ts              ... e.g. Todo更新のコマンド、永続化を行うRepositoryの定義も含む
│
├── domain                            ... ドメインモデル、および、サービスの実装
│   ├── todo.ts                       ... e.g. Todoのドメインモデル / Zodで表現している
│   └── todoService.ts                ... e.g. Todoのサービス / 純粋関数
│
├── infra                             ... インフラとのやりとり
│   ├── CreateTodoRepository.ts       ... e.g. Todoの永続化を、CreateTodoCmdのRepository定義に従って行う
│   ├── UpdateTodoRepository.ts       ... e.g. Todoの永続化を、UpdateTodoCmdのRepository定義に従って行う
│   ├── index.ts
│   ├── schema.ts                     ... drizzle-orm用のスキーマ定義
│   └── types.ts
│
├── islands                           ... HonoX標準のアイランドアーキテクチャ
│   ├── HeaderIsland
│   └── TodoIsland
│
└── routes                            ... HonoX標準のファイルベースルーティング
    ├── index.ts
    └── api
        ├── RPC.ts                    ... hono/client 用にルーティングの型を定義している
        └── todo
            └── [id].ts               ... e.g. /api/todo/:id のルーティング。UpdateTodoCmdを呼び出してる。
```

### routesとislands

routesとislandsはHonoXの標準機能です。routesでファイルベースルーティングを行い、islandsにクライアント側でインタラクションのあるコンポーネントを配置しています。

islandsに配置するコンポーネントの粒度や構成の自由度は高いので、少し悩みました。結果的には、`HeaderIsland`、`TodoIsland` といった大きめのコンポーネントを作成し、その中に細かいコンポーネントを自由に配置するようにしました。

![](/images/sample-todoapp-by-honox/islands.jpg)

```bash
 TodoIsland ... e.g. Todo関連を行うIsland
 ├── AddTodo.tsx
 ├── index.tsx
 ├── TodoItem.tsx
 ├── TodoList.tsx
 └── types.ts
```

理由は大きく2つです。
1. Todoアプリにしても社内向けのツールにしても、インタラクションが全くないコンポーネントの抽出は難しい
    - → コンポーネントは基本、islandsに配置すると割り切り
2. コンポーネントは運用開発しながら諸々変更しやすい方が良い
    - → `XXXIsland`といったroutesから呼び出される入口のコンポーネントを用意。その中身のコンポーネントは、`XXXIsland`外では利用させない。
    - 結果、`XXXIsland`配下の変更の自由度が高い

気をつけた方が良さそうなことは理由1の影響です。
どれもislandsに置くとクライアント側で読み込むハイドレーション用のJavaScriptを読み込みが増えそうです。
今回は、ハイドレーションのJSを304 Not Modifiedで返すように調整しました。
具体的には、hono/vite-build/bun だと304 Not Modifiedで配信する方法がわからなかったので、代わりにhono/vite-build を利用して、自前で静的ファイルのルーティングを行っています。
まだ調整の余地がありそうです。

### domainとcmdとinfra

WIP: ドメインモデル1 に対して、テーブルは複数ある関係
WIP: 型の帳尻合わせ

## 試行錯誤中のこと

### HonoXのcreateRouteの利用とRPC

HonoXでルーティングする時、Honoを直で利用するかcreateRouteを利用するか迷った。自由度は低い方が可読性は高いと思い、結局、createRouteに寄せた。けれど、HonoXでAPIのRPCをしたい時、createRouteに寄せると、RPC用の型をどう作れば良いか悩んだ。結局、DRYではないけれど、RPCしたいエンドポイントを手動で集約した。

https://github.com/kfly8/sample-todoapp-honox-zod-drizzle/blob/06dc286b450ec924d7afca626a3caaff4f4d15bc/app/routes/api/RPC.ts#L3-L14

server.ts で定義しているAppをうまいこと参照すれば、DRYにできそうな気はするけれど、やれていない。
ルーティングに直でHonoを利用すれば、この悩みはなくなるが、悩ましい。

### アイランドアーキテクチャが素朴

HonoX v0.1.33 時点のアイランドアーキテクチャは、自分で用意したHTMLを`<honox-island>`でラップする作りになっていて、とても素朴で理解しやすかったです。バックエンドでなるだけ処理して、HTMLを返す時にインタラクションするための情報を埋め込むアイランドアーキテクチャのアイデア通りの実装で、挙動にびっくりすることがなさそうです。

```jsx
<honox-island component-name="/app/islands/TodoIsland/index.tsx" data-serialized-props="[シリアライズされたデータ]" data-hono-hydrated="true">
   <ul>
       <li>タスク1</li>
       <li>タスク2</li>
    </ul>
</honox-island>
``` 

ンポーネントをislandにするかどうかで`<honox-island>`でラップするかどうかの違いがありDOM構造が変わるので、そこは注意が必要そうに見えています。こちらに関連するissueはあり、見守りたいと思います。
https://github.com/honojs/honox/issues/158

基本islandにいれるようにすれば、あまり問題にならない気もしているので、もう少し使い込んでみたいです。

## まとめ

WIP:

## 参考文献

- アイランドアーキテクチャ
    - [https://jasonformat.com/islands-architecture/](https://jasonformat.com/islands-architecture/) 


