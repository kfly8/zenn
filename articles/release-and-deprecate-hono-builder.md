---
title: "Honoでルーティング定義をBuilderパターンで実装する。おまけにJavaScript ProxyとType Assertionの話"
emoji: "🙄"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['Hono', 'TypeScript']
published: false
---

書いていて、↓だめ。こうするのが一番いいや...
https://github.com/kfly8-sandbox/sample-hono-routing

---

こんにちは。kobakenです。

先日、[hono-builder](https://www.npmjs.com/package/hono-builder)というnpmモジュールをリリースしました。ですが、昨日、deprecateしました。
初めてリリースしたnpmモジュールをすぐdeprecateして、なんとも情けない気持ちです😇 名前空間を一つ無駄にしてすいません!
ここでは作ったことを無駄にしない為にも、いくつかのことを紹介、あるいは供養をしたいと思います。

## Honoでルーティング定義をBuilderパターンで実装する

やりたいことは次の通りです。

1. **ファイル分割ルーティング定義を簡潔にしたい**
    - `app.get('/', ...)`といったHonoの最も簡素なルーティング定義を利用したい。けれど、HonoXは利用しない。
    - RPC用の型を取り出しやすくしたい
2. **エッジ環境での起動を速くするため、サーバーのエントリーポイントを分けやすくしたい**
    - app-server.ts, api-server.ts, admin-server.ts など。
    - heavy-server.tsをlight1-server.ts,light2-server.tsといった風に変更しやすくしたい。インフラの事情で変えやすくしたい

この要件を達するのに、複数のルーティング定義を材料にして Hono インスタンスをつくるBuilderがあれば良かろうと思い、hono-builderを作り始めました。結局、この**BuilderパターンのアプローチはHonoだけで実現できた**ので、拙作のhono-builderはdeprecateしました。

どう実現するのか深堀りしたいと思います。

以下は想定されるディレクトリ構成です。

```bash
src/
├── builder.ts       // Hono Builder
├── app-server.ts    // Server entrypoint for app
├── api-server.ts    // Server entrypoint for app
├── renderer.tsx
├── routes/          // 分割されたルーティング定義ファイルたち
│   ├── _404.tsx
│   ├── _error.tsx
│   ├── root.tsx
│   ├── todos.tsx
│   └── api
│       ├── status.ts
│       └── users.ts
└── ...

```

まず、`src/builder.ts` はBuilderパターンの核となるbuilderオブジェクトを提供します。builderオブジェクトの実態はHonoそのものです。ここで、HonoのmiddlewareやEnvなどあれこれ設定します。

```typescript:src/builder.ts
import { Hono } from 'hono'
import { logger } from 'hono/logger'
import { renderer } from './renderer'

type Env = {
  Variables: {
    hoge: () => void
  }
}

const builder = new Hono<Env>()
builder.use(logger())
builder.use(renderer)

export default builder
```

ルーティング定義は、このbuilderを利用して、`src/routes/` 以下の各ファイルで行います。
例えば、`src/routes/root.tsx` では次のように定義します。Honoの簡潔な書き味のままで、ルーティング定義できて嬉しいです。

```typescript:src/routes/root.tsx
import app from '../builder'

app.get('/', (c) => {
  return c.render(<h1>Hello World</h1>)
})
```

こうやって定義したルーティングを、`src/app-server.ts` や `src/api-server.ts` といったサーバーのエントリーポイントでimportします。
目的に沿ったルーティング定義だけ読み込みして、必要なエンドポイントだけ生えたHonoインスタンスが構築できます。

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

// viteで一括取得する
import.meta.glob('./routes/api/**/!(_*|$*|*.test|*.spec).(ts|tsx)', { eager: true })

import app from './builder'
export default app
```

エントリーポイントを分割したい場合は、importする内容を変えれば実現できます。
こうして、やりたいことはHonoだけで実現できました。

動作例は次のリポジトリで確かめられます。

- https://github.com/kfly8/hono-builder/tree/main/examples
- https://github.com/kfly8-sandbox/hono-vite-rsc-shadcnui

1つ注意としては、開発サーバーでHMRするために、builderオブジェクトの読み込み直しが必要です。
この問題は、例えば、次のようにhotUpdateの設定をして、src/builder.ts をreloadModuleをすれば回避できます。

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

もう1つ気になる点は、builderオブジェクトをグローバルに飼うことになるので、
お行儀の悪いことをすれば全体にも影響を与えることでしょうか。
これを特別、問題視するのであれば、次のセクションのJavaScript Proxy + Type Assertion の実装パターンが役立ちます。

## おまけ: JavaScript Proxy + Type Assertionによる型安全なインタフェース制御

ルーティング定義をしているファイルでは、Hono#fetch,request,fireといったメソッドを呼び出してほしくありません。
この願いを叶えるために、JavaScript Proxy と Type Assertionの組み合わせは強力です。

JavaScript Proxyは、オブジェクトのプロパティアクセスに介入できるJavaScriptの柔軟な機能です（Perlで例えるならVariable::Magicです☺️)
例えば、次のように、objectのmessageプロパティにアクセスした時、「こんにちは」を返すように上書きする、なんてことができます。

```typescript
const example = { message: "hello" }

const trap = function(object) {
  return new Proxy(object, {
    get(target, prop, receiver) {
      // objectのmessageプラパティにアクセスした時、「こんにちは」を返すように上書きする
      if (prop === 'message') {
        return "こんにちは"
      }
      // それ以外は元のまま
      return  Reflect.get(target, prop, receiver)
    }
  })
}

const trapped = trap(example)
console.log(trapped.message) // => 'こんにちは'
```

Type Assertion は、TypeScriptが推測した型を上書きする機能です。いわゆる `as`です。

つまるところ、JavaScript Proxy + Type Assertionは、**値はそのまま、型だけを張り替え、インタフェースを制御できるパターン**になります。

拙作のhono-builderの内部では、BuilderはHonoインスタンスままにしつつ、ルーティング定義中は不要なメソッドを使えないようにしたりしたHonoBuilder interfaceに張替えました。

核のコードは、次の通りシンプルです。それでいて、Honoの型安全性、機能はそのまま享受できます。実態がHonoそのものなので、メンテナンスもしやすいです。継承や自前HonoBuilder classなど他の実装パターンだと、Hono instance構築回りに手間取りこうはいきません。

```typescript
export interface HonoBuilder<
  E extends Env = Env,
  S extends Schema = {},
  BasePath extends string = '/'
> extends Hono<E, S, BasePath> {

  // 不要なメソッドを型レベルで使えないようにする
  fetch: never
  request: never
  fire: never

  // HonoBuilderからHonoに型の張替えをするためのメソッドの型を用意
  build: () => Hono<E, S, BasePath>
}

export function honoBuilder<
  E extends Env = Env,
  S extends Schema = {},
  BasePath extends string = '/'
>(options?: HonoOptions<E>): HonoBuilder<E, S, BasePath> {
  const builder = new Hono<E, S, BasePath>(options) as HonoBuilder<E, S, BasePath>

  const createProxy = (target: typeof builder): typeof builder => {
    return new Proxy(target, {
      get(target, prop, receiver) {

        // HonoBuilderからHonoに型の張替えをするbuildメソッド
        if (prop === 'build') {
          return () => target as Hono<E, S, BasePath>
        }

        // 不要なメソッドを実行時にも使えないようにする
        if (FORBIDDEN_METHODS.has(String(prop))) {
          throw new Error(`.${String(prop)} is not available in HonoBuilder`)
        }

        return Reflect.get(target, prop, receiver)
      },
    })
  }

  return createProxy(builder)
}
```

```
const builder = honoBuilder(); # => 型は HonoBuilder interface / 中身はHono
builder.get('/', (c) => { c.text('hello') })

const app = builder.build(); # => 型も中身もHono
```

面白いですね!

## まとめ

- HonoでBuilderパターンを実装する方法を紹介
- JavaScript Proxy + Type Assertionの実装パターンを、hono-builderを例に用いて紹介

これで供養になったでしょうか。以上です！
