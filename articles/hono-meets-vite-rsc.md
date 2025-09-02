---
title: "Honoでインタラクティブなコンポーネントを作る時、React Server Componentsが良いと思った"
emoji: "🐥"
type: "idea" # tech: 技術記事 / idea: アイデア
topics: ["Hono", "React", "RSC" ]
published: true
---

こんにちは。kobakenです。

![DEMO](/images/hono-meets-vite-rsc/demo.gif)

Honoでこんな感じのインタラクティブなコンポーネントを作りたい場合、CSR、HonoX、[自前でハイドレーション](https://zenn.dev/kfly8/articles/sample-island-architecture-using-hono)、またはNext.js, Wakuなどのフレームワークを利用すると思います。

今回、[React Server Components](https://react.dev/reference/rsc/server-components)(以下、RSC)を試して、良かった点を3つ紹介します。

### 1. `use client` ディレクティブによるエラー検知

地味に嬉しい話からです。コンポーネントをインタラクティブにしたい場合、`use client` ディレクティブをつけますが、この目印のおかげで、使えないhookを利用した場合、Reactは教えてくれます。例えば、次のコードで、もし`use client`していなければ、useStateは使えないよと教えてくれます。

```typescript
"use client"  // これがもしなかったら、TypeError: useState is not a function or its return value is not iterable

import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)
  return (
    <div>
      {count}
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  )
}
```

### 2. 軽量ゆえ、問題が切り分けしやすい

Honoはホントに軽量で、何か気になったことがあればソースコードを読んで理解しやすいです（解読できない時もあります😇）また、RSCの実現にあたって、[@vitejs/plugin-rsc](https://www.npmjs.com/package/@vitejs/plugin-rsc)のおかげでアプリケーションの基盤周りは非常に薄く書けました。こちらのリポジトリの src/rsc/entry.browser.ts, entry.rsc.tsx, entry.ssr.tsx が肝です。**軽量な基盤だと問題の切り分けがしやすくて良い**と思いました。

https://github.com/kfly8-sandbox/hono-vite-rsc-shadcnui

RSC Payloadのencode/decodeやその実行など、RSC自身の複雑さはあるのですが..! / インタラクティブなコンポーネントを作ることに目的を絞れば、複雑さは下がる思います。

### 3. サーバーサイドとフロントエンドの垣根が低い

インタラクティブなコンポーネントは、サーバーサイドレンダリングするコンポーネントとディレクトリを分けて管理することに慣れていたのですが、今回、`use client`ディレクティブを書いて区別し、コンポーネントは同じ箇所にいれるスタイルでやってみました。想像以上に良かったです。

**開発時に意識することはコンポーネントをインタラクティブにしたいかどうかだけ**で、いざインタラクティブとなったら、`use client`をつければ良いだけです。
もちろん、`use client` をトップレベルのコンポーネントにつければハイドレーションコストが上がってしまうので、インタラクティブにする範囲を狭める工夫は必要です。感覚的ですが、ディレクトリが別れていないおかげか、こういった最適化も心理的にしやすいと思いました。

---

その他、UIを全部Reactにお任せできていることはメリットだと思いました。Next.jsやHonoXなどフレームワークを利用していると、Reactだけでなく、そちらの知識も人間やAIエージェントに吸収してもらってUIを書くことになると思いますが、今回、Honoの知識なくとも、UIを書けて良いと思いました。

Honoをベースにしているので、Cloudflare Workersなどエッジサーバーにデプロイしやすかったり、Hono関連のmiddlewareを利用しやすいのも嬉しいポイントです！

RSCを利用していて、気がかりな点が一点。RSCのServer Actionsは様子見しています。というのも、サーバーサイドでしたいことは、Server Actionsを利用せずとも、Honoで実現できると思ったからです。RSCのレイヤーをいれて、わざわざ問題を複雑にする必要はないと感じ、自分の用途には合わないと思いました。

はい！
こんな感じで、インタラクティブなコンポーネントをHonoでつくる場合、RSCが良いと思った話でした。

