---
title: "JavaScript Proxyとtype assertionを利用して、HonoのBuilderパターンを容易にするhono-builderをリリースしてすぐdeprecateしたことを供養したい"
emoji: "🙄"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['Hono', 'TypeScript', 'npm']
published: false
---

こんにちは。kobakenです。

先日、[hono-builder](https://www.npmjs.com/package/hono-builder)というnpmモジュールをリリースしました。

ですが、昨日、deprecateしました。

初めてリリースしたnpmモジュールをすぐdeprecateして、なんとも情けない気持ちです。名前空間を一つ無駄にしてすいません!
ここでいくつかのことを紹介、あるいは供養をしたいと思います。

## HonoだけでBuilderパターン

やりたいことは次の通りです。

1. **ファイル分割ルーティング定義を簡潔にしたい**
  - `app.get('/', ...)`といったHonoの最も簡素なルーティング定義を利用したい。けれど、HonoXは利用しない。
  - RPC用の型を取り出しやすくしたい
2. **エッジ環境での起動を速くするため、サーバーのエントリーポイントを分けやすくしたい**
  - app-server.ts, api-server.ts, admin-server.ts など。
  - heavy-server.tsをlight1-server.ts,light2-server.tsといった風に変更しやすくしたい。インフラの事情で変えたい。

この要件を達するのに、複数のルーティング定義を材料にして Hono インスタンスをつくるBuilderがあれば良かろうと思って、hono-builderを作り始めました。
結局、この**BuilderパターンのアプローチはHonoだけで実現できた**ので、拙作のhono-builderはdeprecateしました。

どう実現するのか深堀りしたいと思います。

以下は想定されるディレクトリ構成です。

```bash
src/
├── builder.ts       // Hono Builder
├── app-server.ts    // Server entrypoint for app
├── api-server.ts    // Server entrypoint for app
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

まず、`src/builder.ts` はBuilderパターンの核となるbuilderオブジェクトを提供します。builderオブジェクトの実態はHonoそのものです。ここで、Honoのmiddlewareなどあれこれ設定します。

```typescript:src/builder.ts
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

```typescript:src/routes/root.tsx
import app from '../builder'

app.get('/', (c) => {
  return c.render(<h1>Hello World</h1>)
})
```

こうやって定義したルーティングを、`src/app-server.ts` や `src/api-server.ts` といったサーバーのエントリーポイントでimportします。
目的に沿ったルーティング定義だけ読み込むのが肝心なところです。こうして必要なルーティングだけ生えたHonoインスタンスを構築できます。

```typescript:src/app-server.ts
import './routes/_404'
import './routes/_error'
import './routes/root'
import './routes/todos'

import app from './builder'
export default app
```

```typescript:src/api-server.ts
import './routes/api/_404'
import './routes/api/_error'

// viteで一括取得するのも👍️
import.meta.glob('./routes/api/**/!(_*|$*|*.test|*.spec).(ts|tsx)', { eager: true })

import app from './builder'
export default app
```

エントリーポイントを分割する場合は、importする内容を変えれば実現できます。こうして、やりたいことはHonoだけで実現できました。
動作例は次のリポジトリで確かめられます。

https://github.com/kfly8-sandbox/hono-vite-rsc-shadcnui

1つ注意としては、開発サーバーでHMRするために、builderオブジェクトの読み込み直しをするために、hotUpdateの設定をする必要があります。

```typescript
import { defineConfig } from 'vite'
import devServer from '@hono/vite-dev-server'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  plugins: [
    devServer({
      entry: 'src/server.ts',
      handleHotUpdate: ({ server, modules }) => {
        const isSSR = modules.some((mod) => (mod as any)._ssrModule)

        if (isSSR) {
          const modulesToReload = ['src/builder.ts']

          for (const modulePath of modulesToReload) {
            const absolutePath = path.join(__dirname, modulePath)
            const module = server.moduleGraph.getModuleById(absolutePath)

            if (module) {
              server.reloadModule(module)
            }
            else {
              console.log(`Module not found for hot reload: ${absolutePath}`)
            }
          }

          server.hot.send({ type: 'full-reload' })
          return []
        }
      },
    })
  ]
})
```

## 2. JavaScript Proxy + type assertionによる型安全なインタフェース制御

hono-builderの実装で一番工夫したのは、**JavaScript ProxyとTypeScriptのtype assertionを組み合わせた実装パターン**です。
このパターンは強力で面白いです。**値はそのままで、型だけを張り替える**ことで、インタフェースの制御できます。

今回は、Honoの型安全性を完全に享受しながら、`build()`メソッドなど独自のメソッドを生やしたり、ルーティング定義中は不要なメソッドを使えないようにしましたが、既存のライブラリをラップして独自のインタフェースを提供したい場合にも応用できます。

基本的な考え方はこうです：

```typescript
TODO

```

hono-builderでは、例えば、xxxはルーティング定義中は利用できないように制御を入れていました。

```typescript
import { honoBuilder } from 'hono-builder'

const builder = createBuilder()
builder....

const app = builder.build()
```


## まとめ

TODO

