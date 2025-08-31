---
title: "HonoでReact Server Componentsを試して、良いと思った"
emoji: "🐥"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["Hono", "React", "RSC" ]
published: false
---

こんにちは。kobakenです。

Honoで、[React Server Components](https://react.dev/reference/rsc/server-components)(以下、RSC)を試してみました。こんな具合にインタラクティブなコンポーネントを作れます。

![DEMO](/images/hono-meets-vite-rsc/demo.gif)

---

- サンプルページ: https://hono-vite-rsc-shadcnui.kfly8.workers.dev/
- サンプルページのリポジトリ: https://github.com/kfly8-sandbox/hono-vite-rsc-shadcnui

---

従来、Honoでインタラクティブなコンポーネントを作りたい場合、CSR、HonoX、[自前でハイドレーション](https://zenn.dev/kfly8/articles/sample-island-architecture-using-hono)、またはNext.js, Wakuなどのフレームワークを利用することになると思います。

そういった中で、今回の Hono + Vite + RSCの次の2点が特に良いと感じました。

1. `use client` ディレクティブ
2. 軽い基盤

### 1. `use client` ディレクティブ

`use client`と書くだけで、コンポーネントがインタラクティブになるというのは想像以上に嬉しかったです。

1. とりあえず、コンポーネントを書く
2. インタラクティブにしたい箇所だけ、`use client`と書く

といった感じの開発をすれば、あとは勝手に、SSRされて必要な箇所だけハイドレーションされます。意識することは、コンポーネントをインタラクティブにしたいかどうかだけで、バックエンドとフロントエンドの垣根の低さが良いと思いました。

### 2. 軽い基盤

Honoは軽量フレームワークで、何か気になったことがあればソースコードを読んで理解しやすいのが嬉しいです（もちろん解読できない時もあります😇）
また、今回、RSCを実現にあたって、[@vitejs/plugin-rsc](https://www.npmjs.com/package/@vitejs/plugin-rsc)のおかげでRSCの周りのコードが簡潔に書けました。

RSC自体が軽いかというと疑問符がつきますが、RSCを動かすための基盤が薄いことで、問題の切り分けがしやすくて良いです。

---

その他、エッジサーバーで動くこと、レンダリングがReactで完結してHonoの知識をAIに与えなくても動かしやすいことも良いと思いました。

一方、RSCのServer Actionsは様子見しています。というのも、サーバーサイドでしたいことは、Server Actionsを利用せずとも、Honoで実現できると思ったからです。
RSCのレイヤーをいれて、わざわざ問題を複雑にする必要はないと感じ、自分の用途には合わないと思いました。自分の理解不足もありそうですが、今後の動向を見守りたいと思います。  

はい！
そんな感じで、Hono + Vite + RSCの組み合わせは良いと思いました。
