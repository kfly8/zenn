---
title: "HonoXでTodoアプリを作った感想"
emoji: "☺️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ['Hono','HonoX','Zod','Drizzle ORM']
published: false
---

はじめまして。kobakenです。

次の3つの要件を満たす社内向けWebアプリケーションを作るにあたり、[サンプルのTODOアプリケーションを作成した](https://github.com/kfly8/sample-todoapp-honox-zod-drizzle)ので、その感想を書きます。

- 要件1. セルフホストが簡単。特にデータは、自身で管理、所持できる
- 要件2. ソースを公開した時に、多くの人にとっつき易いと感じてもらえたら嬉しい
- 要件3. 開発チームは私ひとり。企画も営業も私。認知負荷を極力下げたい

ざっくりな要件ですね☺️

筆者自身は、ISUCON10,11,12,13,14でPerlへの移植作業に関わったり、[YAPC::Hiroshima 2024](https://yapcjapan.org/2024hiroshima/) の運営だったりと、Perlで生活しています。今回採用したバックエンドTypeScriptの経験は無いです。用語を間違って使っていたりしたら、椅子を投げてもらえるとありがたいです。

## 採用した技術スタックとその採用理由

要件を踏まえて、次の技術スタックを利用してます。

- Language / Runtime
    - TypeScript
    - [Bun v1.2](https://bun.sh/)
- Web Application Framework
    - [Hono](https://hono.dev/)
    - [HonoX](https://github.com/honojs/honox)
- Database / ORM
    - [SQLite](https://www.sqlite.org/)
    - [Drizzle ORM](https://orm.drizzle.team/)
- Validation, Domain Modeling
    - [Zod](https://zod.dev/)
- misc
    - [neverthrow](https://github.com/supermacro/neverthrow)
    - [Tailwind CSS v4](https://tailwindcss.com/)

### TypeScript と Bun を選んだ理由

Webアプリケーションのビューは、TSX以外で書きたくないと思えるくらい他の言語と体験に違いがあると思っています。加えて、今回の要件的に、スケールのことは考えなくて良く、また言語切り替えの認知負荷を下げたいので、フロントエンド、バックエンド両方ともTypeScriptで書いてみようと思いました。

一休さん、トグルホールディングスさん、ピクスタさんの採用事例に影響を受けています。

@[speakerdeck](cb2e31ccf3c44779893bfd4eb0f86dca)

@[speakerdeck](df251937942c48d3a773d93b6ccd4bcc)

@[speakerdeck](c8556affd0f3401388af6d664d320c42)

また、TypeScriptの処理はBunに任せました。Bunには何でも入っていて、一人開発の負担を減らせそうです。例えば、テスティングフレームワークがバンドルされていて、超高速に動作するようです。[最近、1.2が出ていました](https://bun.sh/blog/bun-v1.2)が、異常な気合いで何でも入ってる感じがします。

### Hono と HonoX を選んだ理由

Honoを選んだ理由ですが、合理的な理由もありますが「Hono 面白そう！」という気持ちで選んでることは隠せないです。

調べてみると、yusukebeさんがHonoの最初のコミットをして2.5ヶ月後に、YAPCのトークがあったようです。それから2年も経ってしまいました。
https://x.com/yusukebe/status/1499989656124858373 

[HonoをPerlに移植するPono](https://github.com/kfly8/pono)を細々と書いていて、なぜかHonoのソースコードはよく読んでいます。それもあって、Honoはソースコード込みで、コアがシンプルだと感じています。(Honoの型関連のコードは、実処理より三段階くらい難しく感じていて、こちらは勘で読んでます☺️)

加えて、Web標準にも沿っているので、運用はどうにでもなりそうな感じがして好みです。

HonoXは、Vite周りの設定を省略して開発を始められそうなことと、ファイルベースルーティングで単調なつくりにしやすそうなので選びました。

### その他の選んだ理由

- SQLite
    - SQLiteならデータは一枚のファイルに収まるので、データを管理、所持する要件にお手軽に合いそうです。
- Drizzle ORM
    - SQLの実行計画が想像しやすく、型によるサポートが強そうなので選びました。
- Zod
    - 他のバリデーションツールを知らないので、積極的な理由はなく、馴染みがあったので選んでます。
    - 普段、Perlの型制約ライブラリのType::Tinyを使い倒しているのですが、それと似た感覚で使ってます。[ZodをPerlに移植するPoz](https://metacpan.org/pod/Poz)を読んでいた影響もあります。
    - 後述しますが、ドメインモデリングもZodに大半を任せる設計にしました。
- neverthrow
    - TypeScriptにResult型を提供するモジュールです。想定内のエラーは型情報に現れた方がハンドリング漏れしないので利用してます。
- Tailwind CSS v4
    - UIライブラリが豊富なので、選んでます。
    - 最近リリースされたv4でも、すんなり動いています。

### 採用していない技術スタックについて

採用しなかった技術スタックについても少し触れておきます。

- React
    - hono/jsxでどこまでできるのか試してみたかったので、たまたま利用していないだけです。
    - 表現したいUIやライブラリの状況次第では、Reactに変更すると思います。
    - ただ、依存は少ない方が管理が楽になるので、依存しないで済む世界観になったら良いと思っています。
- [Bun sql](https://bun.sh/docs/api/sql)
    - 慣れたSELECT文で書けることは魅力ですが、型によるサポートが弱い印象があり、今回見送っています。
    - 薄く作るならこれで十分だろうと感じています。

----

## 採用したアーキテクチャ

ただのTodoアプリですが、後々変更しやすい別のアプリケーションを作りたいので、ちょっと凝った作りにしています。例えば、こんなことを意識しています。

- ドメインはドメインに集中して、インフラの知識は別問題として切り離したい。逆も然り。
- 単純過ぎてあくびが出るくらい退屈な作りにしたい

こちらを踏まえて、依存の逆転、コマンドパターン、リポジトリパターンを利用しています。以下、具体的にみていきたいと思います。

### ディレクトリ構成

ディレクトリは次のような構成になっています。それぞれ簡単に説明します。

```bash
app
├── client.ts ... HonoX標準のクライアントのエントリーポイント
├── server.ts ... HonoX標準のサーバーのエントリーポイント
├── style.css ... Tailwind CSSのエントリーポイント
│
├── cmd ... コマンドパターンの実装
│   ├── CreateTodoCmd.ts ... e.g. Todo作成のコマンド、永続化を行うRepositoryの定義も含む
│   └── UpdateTodoCmd.ts ... e.g. Todo更新のコマンド、永続化を行うRepositoryの定義も含む
│
├── domain ... ドメインモデル、および、サービスの実装
│   └── todo.ts ... e.g. Todoのドメインモデル
│
├── infra ... インフラとのやりとり
│   ├── CreateTodoRepository.ts ... e.g. Todoの永続化を、CreateTodoCmdのRepository定義に従って行う
│   ├── UpdateTodoRepository.ts ... e.g. Todoの永続化を、UpdateTodoCmdのRepository定義に従って行う
│   ├── index.ts
│   ├── schema.ts ... drizzle-orm用のスキーマ定義
│   └── types.ts
│
├── islands ... HonoX標準のアイランドアーキテクチャのコンポーネント配置
│   ├── HeaderIsland
│   └── TodoIsland
│
└── routes ... HonoX標準のファイルベースルーティング
    ├── index.ts
    └── api
        ├── RPC.ts ... hono/client 用にルーティングの型を定義している
        └── todo
            └── [id].ts ... e.g. /api/todo/:id のルーティング。UpdateTodoCmdを呼び出してる。
```

### routesとislandsについて

routesとislandsはHonoXの標準機能です。routesでファイルベースルーティングを行い、islandsにインタラクションのあるコンポーネントを配置しています。

islandsに配置するコンポーネントの粒度や構成の自由度は高いので、判断に少し悩みました。結果的には、`HeaderIsland`、`TodoIsland` といった大きめのislandコンポーネントを作成し、その中に細かいコンポーネントを自由に配置するようにしました。

![](/images/sample-todoapp-by-honox/islands.jpg)


```bash
 TodoIsland ... e.g. Todo関連を行うIsland
 ├── AddTodo.tsx
 ├── index.tsx
 ├── TodoItem.tsx
 ├── TodoList.tsx
 └── types.ts
```

こういった判断をした理由は、大きく2つあります。

1. Todoアプリにしても社内向けのツールにしても、インタラクションが全くないコンポーネントの抽出は難しいと感じた
    - → コンポーネントは基本、islandsに配置すると割り切っても良いのではないか？
2. コンポーネントは運用開発しながら諸々変更しやすい方が良い
    - → `XXXIsland`といったroutesから呼び出される入口のコンポーネントを用意。その中身のコンポーネントは、`XXXIsland`外では利用させない。
    - 結果、`XXXIsland`配下の変更の自由度が高くする。

1つ目の判断に関しては少し心配事があります。クライアント側で読み込むハイドレーション用のJavaScriptが増え問題になるのではないか？と心配しています。
とはいえ、SPAを扱っていたときは、随分沢山クライアントにJavaScriptを読み込ませていたことを思えば、気にしすぎな気もします。今回は試しに、vite buildして得られたハイドレーション用のJavaScriptを304 Not Modifiedで返すように調整しました。これだけのために、前段のサーバーを起きたくなかったのでHonoで完結させています。具体的には、hono/vite-build/bun でEtagを指定する方法がわからなかったので、代わりにhono/vite-build を利用して、自前で静的ファイルのルーティングを行っています。viteの開発サーバーでは、何もせずともハイドレーション用のJavaScriptは304を返していたので、調整の余地がありそうです。

### domainとcmdとinfra について

ロジックの実装は、関数型ドメインモデリングに影響を受けた作りになっています。

ドメインモデルは次のようにZodで定義しています。

```typescript
// Todoのドメインモデル
export const todoSchema = z.object({
	id: todoIdSchema,
	title: z.string().min(1).max(100),
	description: z.string().max(1000),
	completed: z.boolean(),
	authorId: userIdSchema,
	assigneeIds: z.array(userIdSchema),
});

export type Todo = z.infer<typeof todoSchema>;
```

振る舞いはResult型を返す純粋関数として実装しています。

```typescript
export type CreateTodoParams = PartialBy<
	Omit<Todo, "id">,
	"description" | "completed" | "assigneeIds"
>;

// Todoドメインモデルを作成する関数
export function createTodo(params: CreateTodoParams) {
	const todo = {
		...params,
		// default values
		description: params.description ?? "",
		completed: params.completed ?? false,
		assigneeIds: params.assigneeIds ?? [],
		id: createTodoId(),
	};

	const parsed = todoSchema.safeParse(todo);
	if (parsed.error) {
		return err(parsed.error);
	}

	return ok(parsed.data);
}
```

細かい工夫ですが、データを一意に識別するidはBrand型で定義して、idの取り違えといったバグの予防をしています。

```typescript
const todoIdSchema = z.string().brand<"TodoId">();
```

蛇足ですが、Todo自身はBrand型にしていません。idがbrandingされていれば識別で間違える可能性は低いと考えて、取り回し易さを優先しています。

ZodとTypeScriptを利用すると、簡便にデータの詳細を記述できてよかったです。このデータを、コマンドパターンとリポジトリパターンでSQLiteに永続化しています。

コマンドパターンは、アプリケーションの操作をオブジェクト化するパターンです。お気に入りのポイントは一貫性で、アプリケーションのどの操作もexecuteで呼び出せるのが単純で良いと感じています。

リポジトリパターンは、インフラ処理を抽象化して、ドメインモデルを永続化するために利用しています。次のコードであれば、Todoドメインモデルを永続化するRepositoryインターフェースをコマンドで定義して、これをインフラ層で実装しています。

```typescript
// コマンドの実装
import { err, ok } from "neverthrow";
import type { Result } from "neverthrow";
import type { CreateTodoParams, Todo } from "../domain/todo";
import { createTodo } from "../domain/todo";
import type { Cmd } from "./types";

export type RepositoryParams = {
	todo: Todo;
};

export interface Repository {
	save(params: RepositoryParams): Promise<Result<null, Error>>;
}

export class CreateTodoCmd implements Cmd {
	// リポジトリを注入
	constructor(private repo: Repository) {
		this.repo = repo;
	}

	async execute(params: CreateTodoParams) {
		const result = createTodo(params);
		if (result.isErr()) {
			return err(new Error("Failed to create todo", { cause: result.error }));
		}
		const todo = result.value;

		const saved = await this.repo.save({ todo });
		if (saved.isErr()) {
			return err(new Error("Failed to save todo", { cause: saved.error }));
		}

		return ok(todo);
	}
}
```

このCreateTodoCmdのリポジトリのインフラの実装は、ここに置いてます。
https://github.com/kfly8/sample-todoapp-honox-zod-drizzle/blob/main/app/infra/CreateTodoRepository.ts


総じて、ドメインとインフラの分離ができているので、それぞれ変更しやすいアーキテクチャになっていると感じています。
このアーキテクチャが単純過ぎて、あくびがでるかはちょっとわからないです。

## 感想や試行錯誤中のこと

### HonoXのcreateRouteの利用とRPC

HonoXでルーティングする時、Honoを直で利用するかcreateRouteを利用するか迷いました。自由度の低い手段の方が読む時に考えることが減るので、createRouteに寄せようにしました。こうしたときに、RPC用の型の抽出はどうすれば良いか悩みました。結局、DRYではないですが、RPCしたいエンドポイントを手動で集約しました。server.ts で定義しているAppをうまいこと参照すれば、DRYにできそうな気はするのですが、やれていないです。そもそも、ルーティングをHonoの直利用にすれば、この悩みはなくなりますが、それはそれで自由度が高すぎるような気がして、悩ましいと思っています。

https://github.com/kfly8/sample-todoapp-honox-zod-drizzle/blob/06dc286b450ec924d7afca626a3caaff4f4d15bc/app/routes/api/RPC.ts#L3-L14

### ZodとDrizzle ORMの型の整合性

Zodで定義したスキーマとdrizzleのスキーマで型が合わなかった時、どうすべきか悩みました。結局、次の整理にしています。

- Zod側/ドメイン側の制約を優先する（これはごく自然）
- スキーマでdefaultやoptionalを利用しない（これが工夫）
    - defaultやoptionalを利用したい場合は、ドメインモデルを作成する関数のパラメタをoptionalをいれる（上記の例ならPartialByを利用している）
    - defaultやoptionalは利便性のために用意されているもの。

もし、Zod側のスキーマでoptionalを利用し、Drizzle ORMのスキーマ側でNonNullとした場合、`Type 'boolean | undefined' is not assignable to type 'boolean | SQL<unknown> | Placeholder<string, any>'.` といった型エラーがでました。今となっては、それはそうといった挙動なのですが、最初は戸惑いました。

### アイランドアーキテクチャが素朴

HonoX v0.1.33 時点のアイランドアーキテクチャは、`<honox-island>`でラップする作りになっていて、素朴で理解しやすかったです。この実装を初めて読んだ時、シンプル！これでいけるんだ！と興奮しました。（もちろん、これだけで実装で全て完結しているわけではないですが...）

```html
<honox-island component-name="/app/islands/TodoIsland/index.tsx" data-serialized-props="[シリアライズされたデータ]" data-hono-hydrated="true">
   <ul>
       <li>タスク1</li>
       <li>タスク2</li>
    </ul>
</honox-island>
``` 

[Preact作者のJason Miller氏のこの記事](https://jasonformat.com/islands-architecture/)を読んで、そもそも、アイランドアーキテクチャのアイデア自体が素朴で、バックエンド側でなるだけ処理して、インタラクションのある箇所に関してだけ、ハイドレーションするのは理にかなってると感じました。

ただ、islandコンポーネントになると、`<honox-island>`がラップしてDOM構造が変わるので、CSSの親子関係のセレクタを利用するなどDOM構造に依存したコードを書く場合、注意が必要そうです。（関連issue: https://github.com/honojs/honox/issues/158 ) とはいえ、私の場合、islandコンポーネントの単位を大きめに取っていて、islandコンポーネント内で物事が解決するため、問題にならなそうと思っています。

繰り返しになりますが、HonoXのアイランドアーキテクチャは、シンプルで理解しやすく、SSRとクライアント側のインタラクションを手軽に両立できる点が魅力だと感じました。

## まとめ

HonoXやZod、Drizzle ORMを利用して、サンプルのTODOアプリケーションを作成しました。

https://github.com/kfly8/sample-todoapp-honox-zod-drizzle

