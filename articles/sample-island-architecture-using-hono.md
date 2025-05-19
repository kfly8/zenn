---
title: "Honoでアイランドアーキテクチャを自前実装する"
emoji: "😺"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['Hono']
published: true
---

こんにちは。kobakenです。

従来、静的なHTMLをインタラクティブなHTMLにハイドレーションする場合、Next.js, Fresh, HonoX なり、フレームワークにお任せすると思います。
それが正解だと思いつつ、今回、Honoでアイランドアーキテクチャをお試し実装してみた感想を書きます。

わざわざ自前実装をしてみたキッカケは、Honoで小さなアプリケーションを作っている時に、shadcn/uiを利用したくなったのですが、これを動作させるにはハイドレーションが必要になったからです。
この解決のために、フレームワークを上乗せするのは大袈裟に感じられて、自前実装しました。（自前実装は大袈裟ではないのか？というツッコミもありそうですが、気にしないでください😀）
加えて、ガチャガチャ実装を進めていると、ハイドレーション技術はチューニングのしがいがあることに気づき、一度自前実装しておけば、各フレームワークの意図が掴みやすくなりそうだと思いより楽しめました。

結果として、できたものはこのリポジトリです。**[肝の実装はたった162行です](https://github.com/kfly8-sandbox/sample-hono-island-architecture/blob/main/src/client.tsx)**

https://github.com/kfly8-sandbox/sample-hono-island-architecture

この自前アイランドアーキテクチャ実装のオモシロポイントは、次の3つです。

1. viteを利用して、ハイドレーションが必要なコンポーネントだけ読み込みする
2. IntersectionObserverを利用して、表示されていないコンポーネントのハイドレーションを後回しにする
3. requestIdleCallbackを利用して、メインスレッドの利用を減らす

---

## ハイドレーション技術とそのチューニング

ハイドレーション技術は静的なHTMLをインタラクティブなHTMLに変換する技術です。具体的には、サーバーレンダリングした静的なHTMLを、クライアント側で`react-dom/client`の`hydrateRoot`などを使ってイベント登録等する技術です。貧弱な端末を利用しているユーザーであってもサーバ側でレンダリングすれば素早くコンテンツが届けられ、それでいてインタラクションを実現できるのが嬉しいところです。

ただ、1000個、2000個と沢山のコンポーネントを一度にハイドレーションをすれば具合は悪くなります。**ユーザーにとって必要なコンポーネントを必要なタイミングでハイドレーションすることが、良いパフォーマンスに繋がります**。

例えば、アイランドアーキテクチャはその工夫の１つです。これは、ハイドレーションが必要なコンポーネントを「島」に見立て、処理が必要な範囲を限定するアプローチです。この概念はPreactの作者による[解説記事](https://jasonformat.com/islands-architecture/)が分かりやすいです。

余談ですが、そもそもユーザーに届けた時点で最初からインタラクティブなHTMLであれば、ハイドレーションは不要です。これは従来のDOM操作直結型のコードで実現できますが、このようなUIとDOMが密結合したコードは扱いづらく、現代の宣言的UIの利点が無くなります。Ref: https://codesandbox.io/p/sandbox/distracted-panna-rsvn9n

```html
<!DOCTYPE html>
<html>
  <body>
    <button id="counter-button">Click me!!</button>
    count: <span id="counter">0</span>
    <script defer type="application/javascript">
      document.addEventListener('DOMContentLoaded', () => {
        // DOMを参照して、DOM操作する昔ながらのコード？
        const button = document.getElementById('counter-button');
        const counter = document.getElementById('counter');

        let count = 0;
        const setCount = (c) => { count = c };
        const render = () => {
          counter.textContent = count;
        };

        button.addEventListener('click', () => {
          const count = parseInt(counter.textContent, 10);
          setCount(count + 1);
          render()
        });
      })
    </script>
  </body>
</html>
```

この点に関して、Qwikがハイドレーション不要なアプローチを取っていて興味深いです。ただし、これを自前で簡単に実装できるとは思いませんでした😇

## 自前アイランドアーキテクチャ実装のオモシロポイント解説

FreshやAstroなどの既存フレームワークは、開発者がハイドレーションをほとんど意識せずに済むよう設計されています。しかし今回は、不要な要件です。コンポーネント記述が多少冗長になったとしても、ハイドレーション周りのコードを簡潔に保ちながら、必要なタイミングで必要な箇所だけをハイドレーションする細やかな制御に注力したいと思います。

### 1. viteを利用して、ハイドレーションが必要なコンポーネントだけ読み込みする

まず、ページ内で必要なコンポーネントだけを読み込む仕組みを実装しました。[HonoXのハイドレーション](https://github.com/honojs/honox/blob/f03af559830a029abd125745236013535e4914c5/src/client/client.ts#L38)を参考に、viteのimport.meta.glob機能を活用して、ハイドレーションが必要な要素だけを抽出します。具体的には、HTMLのdata属性に格納された情報を基に、必要なコンポーネントを動的にインポートして実現します。

```typescript
// ハイドレーション可能なコンポーネントをかき集める
const COMPONENT_MODULES = import.meta.glob<ComponentModule>('./islands/*.tsx', { eager: false }) as GlobModules

async function hydrateAllIslands() {
  const islands = document.querySelectorAll('[data-app-hydrated]')

  // islandsの読み込み優先順位をつけ、
  // 優先順位の高いものから hydrateIsland を呼び出す
}

async function hydrateIsland(element: Element, componentName: string) {
    // 必要なコンポーネントを読み込み
    const importedModule = await COMPONENT_MODULES[modulePath]() as ComponentModule
    const Component = importedModule[componentName] ?? importedModule.default

    // hydrate!!
    hydrateRoot(element, createElement(Component, props)
}
```

### 2. 表示されてないコンポーネントのハイドレーションを後回しにする

次に、ハイドレーションの優先順位をつけていきます。ページを読み込んだ時に画面に表示されていないコンポーネントは、明らかに後回しにしてよいと思いました。これは、[IntersectionObserver](https://developer.mozilla.org/en-US/docs/Web/API/IntersectionObserver) APIを活用し、以下のようなコードで実現しました。

```typescript
// 各アイランドについて表示されているかどうかを判断
islands.forEach(island => {
const observer = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      visible.push(island);
    } else {
      hidden.push(island);
    }
    observer.disconnect();
  });
}, { rootMargin: '200px' }); // 画面の上下200pxの範囲も「表示されている」と判断

observer.observe(island);
});
```

蛇足ですが、`rootMargin: '200px'` のような処理を挟みやすいのは自前実装ならではですね😅

### 3. メインスレッドの利用を減らす

最後に、ハイドレーション処理がメインスレッドを占有することによって、ユーザー操作が妨げられる問題を解消しました。具体的には、ブラウザがアイドル状態のときにのみ処理を進める[requestIdleCallback](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestIdleCallback) APIを活用してみました。

```typescript
  const processBatchWithIdleCallback = (islands: Element[], priority: 'high' | 'low') => {
    let index = 0;
    const highPriority = priority === 'high';
    const options = highPriority ? { timeout: 500 } : undefined; // 高優先度の場合はタイムアウト設定を短くする

    const processNextBatch = (deadline: IdleDeadline) => {
      // 一度に処理するバッチサイズ（高優先度の場合は多め、低優先度の場合は少なめ）
      const batchSize = highPriority ? 3 : 1;
      let processedInThisBatch = 0;

      // アイドル時間がある限り、指定のバッチサイズまたはアイドル時間が尽きるまで処理する
      while (index < islands.length &&
            (highPriority || deadline.timeRemaining() > 0) &&
            processedInThisBatch < batchSize) {
        const island = islands[index];
        const componentName = island.getAttribute('data-app-component')!;

        // 非同期処理のため、即座に次のアイランドに移る
        hydrateIsland(island, componentName).then(() => {
          island.setAttribute('data-app-hydrated', 'true');
        });

        index++;
        processedInThisBatch++;
      }

      // まだ処理すべきアイランドが残っている場合は、次のアイドル時間に処理を予約
      if (index < islands.length) {
        requestIdleCallback(processNextBatch, options);
      } else {
        console.log(`Completed hydration of all ${islands.length} ${priority} priority islands`);
      }
    };

    requestIdleCallback(processNextBatch, options);
  };

  // 表示されているアイランドを高優先度でバッチ処理
  if (visible.length > 0) {
    processBatchWithIdleCallback(visible, 'high');
  }
```

## 終わりに

必要なコンポーネントが必要なタイミングでハイドレーションされるように、自前アイランドアーキテクチャを実装してみました。IntersectionObserver, requestIdleCallbackなど道具が揃っていて、結果160行程度で実現でき、思ったより簡単に実現できたというのが正直な感想です。AI Agentも十分機能してくれて、役立ちました。以上です！
