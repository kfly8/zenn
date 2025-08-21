---
title: "JavaScript Proxyとtype assertionを利用して、Honoのルーティング定義をビルダーパターンを容易にするhono-builderをリリースしてすぐdeprecateしたことを供養したい"
emoji: "🙄"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['Hono', 'TypeScript', 'npm']
published: false
---

こんにちは。kobakenです。

先日、[hono-builder](https://www.npmjs.com/package/hono-builder)というnpmモジュールをリリースしました。HonoでBuilderパターンを簡単に実現するためのモジュールで、ルーティング定義のファイル分割やマルチエンドポイントをやりやすくしてくれるものでした。

ですが、今日、deprecateしました。

初めてリリースしたnpmモジュールが即deprecate!!となんとも情けない結果です。が、ここでいくつかのことを紹介、あるいは供養をしたいと思います。

## Honoだけでやりたいことは実現できるからdeprecateした

deprecateした理由は、**Honoで全て実現できることがわかったから**です。不要なラッパーを作りました😇

とはいえ、実装の過程で得られた知見は無駄ではなかったと思うところもあり、以下、hono-builderが提供しようとしていた機能と、それがHonoでどう実現できるか、そして実装で工夫した点を紹介します。

## 1. HonoでBuilderパターンを実現する方法

やりたいことは次の2つです。

1. ファイル分割してルーティング定義を簡潔にしたい
2. マルチエンドポイントを簡単に実現する

もう少し具体的には、以下のようなファイル構成でルーティング定義を行いたいと考えていました。


```bash
src/
├── builder.ts       // Setup HonoBuilder
├── server.ts        // Endpoint for all routes
├── api-server.ts    // Endpoint for API routes
├── renderer.tsx
├── routes/          // Define routes as separate files
│   ├── _404.tsx
│   ├── _error.tsx
│   ├── root.tsx
│   ├── todos.tsx
│   └── api
│       ├── status.ts
│       └── users.ts
└── ...

```

ここで、`src/builder.ts` は核になるbuilderを提供します。このHonoのbuilderで、Honoのmiddlewareをあれこれ設定します。

```typescript
import { Hono } from 'hono'
import { logger } from 'hono/logger'
import { renderer } from './renderer'

const builder = new Hono()
builder.use(logger())
builder.use(renderer)

export default builder
```

ルーティング定義は、このbuilderを利用して、`src/routes/` 以下の各ファイルで行います。
例えば、`src/routes/root.tsx` では次のように定義します。Honoの簡潔な書き味ままで、ルーティング定義できて嬉しいです。

```typescript
import app from '../builder'

app.get('/', (c) => {
  return c.render(<h1>Hello World</h1>)
})
```


こうやって定義したルーティングを、`src/server.ts` や `src/api-server.ts` といったサーバーのエンドポイントでimportして、Honoのアプリケーションを構築します。

```typescript
# src/server.ts
import './routes/_404'
import './routes/_error'
import.meta.glob('./routes/**/!(_*|$*|*.test|*.spec).(ts|tsx)', { eager: true })

import app from './builder'

export default app
```

```typescript
# src/api-server.ts
import './routes/api/_404'
import './routes/api/_error'
import.meta.glob('./routes/api/**/!(_*|$*|*.test|*.spec).(ts|tsx)', { eager: true })

import app from './builder'

export default app
```

マルチエンドポイントは、エッジ環境を意識しています。
必要最低限のルーティングだけをもったエンドポイントであれば、
サーバーの起動時間に寄与するのではないかと思ったからです。


この実装パターンの動作例は次のリポジトリで確認できます。

- https://github.com/kfly8-sandbox/hono-vite-rsc-shadcnui

## 2. JavaScript Proxy + type assertionによる型安全なI/F制御

hono-builderの実装で一番工夫したのは、**JavaScript ProxyとTypeScriptのtype assertionを組み合わせた実装パターン**です。

Honoの型安全性を完全に享受しながら、`build()`メソッドなど独自のメソッドを生やしたり、ルーティング定義中は不要なメソッドを使えないようにしました。

### 実装の仕組み

基本的な考え方はこうです：

```typescript
// 簡略化した実装例
type Builder<T> = {
  get: (...args: Parameters<Hono['get']>) => Builder<T>
  post: (...args: Parameters<Hono['post']>) => Builder<T>
  build: () => T
  // Honoの他のメソッドは意図的に公開しない
}

function createBuilder(): Builder<Hono> {
  const hono = new Hono()
  
  // Proxyでメソッド呼び出しをインターセプト
  return new Proxy(hono, {
    get(target, prop) {
      // HTTPメソッドの場合はチェーンを継続
      if (['get', 'post', 'put', 'delete', 'patch'].includes(prop as string)) {
        return (...args: any[]) => {
          (target as any)[prop](...args)
          return this // Builderを返してチェーンを継続
        }
      }
      
      // buildメソッドの場合は元のHonoインスタンスを返す
      if (prop === 'build') {
        return () => target
      }
      
      // その他のメソッドはアクセス不可
      throw new Error(`Method ${String(prop)} is not available during building`)
    }
  }) as Builder<Hono>
}
```

この実装パターンの面白いところは、**値はそのままで、型だけを張り替える**ことで、I/Fを制御している点です。

### なぜこのパターンが強力なのか

1. **型安全性の維持**: Honoの型情報を完全に保持しながら、独自のI/Fを提供できる
2. **段階的な制限**: ビルド中は特定のメソッドだけ使えるようにし、ビルド後は全機能を開放する
3. **実行時のバリデーション**: Proxyを使うことで、実行時にも不正な操作を防げる

例えば、こんな使い方ができます：

```typescript
const builder = createBuilder()
  .get('/users', handler)
  .post('/users', handler)
  // .use(middleware) // ← これはエラー！ビルド中は使えない
  
const app = builder.build()
app.use(middleware) // ← ビルド後なら使える
```

このパターンは、Honoに限らず、既存のライブラリをラップして独自のI/Fを提供したい場合に応用できます。TypeScriptの型システムとJavaScriptの動的な性質を組み合わせた、なかなか面白いアプローチだと思っています。

## まとめ

hono-builderは、結果的に不要なモジュールでした。

しかし、この失敗から得られた教訓は大きかったと思います：

1. **既存のライブラリの機能を十分に理解してから作る**: Honoの機能を完全に把握していれば、最初から作る必要がなかった
2. **Proxy + type assertionパターンの強力さ**: 既存ライブラリのI/Fを型安全に制御する手法として応用が効く
3. **失敗を恐れずに公開することの価値**: deprecateは恥ずかしいけれど、実装過程で得た知見は確実に次に活きる

初npmモジュールがすぐさまdeprecateという情けない結果になりましたが、これも良い経験だったと思うことにします。車輪の再発明をしてしまったとしても、その過程で車輪の仕組みがよくわかったのだから、それはそれで価値があったのではないでしょうか。

もしhono-builderに興味を持っていただいた方がいたら、[GitHubリポジトリ](https://github.com/kfly8/hono-builder)にソースコードは残してあります。実装の参考になれば幸いです。

そして、Honoは素晴らしいフレームワークです。私が余計なラッパーを作る必要がないくらい、必要な機能が揃っています。これからもHonoを使い倒していきたいと思います。

