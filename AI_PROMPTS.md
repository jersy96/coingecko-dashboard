# AI Prompts Log

How AI was used to build this project, and where it got things wrong.

## Key prompts

### Scaffolding the dockerized Rails app

The prompt that produced the empty app fixed everything that is expensive to change later, and defined a single acceptance criterion instead of describing the result:

> Create an EMPTY, dockerized Rails application at the root. Latest stable versions, verified — Rails 8.1.4, Ruby 4.0.7. **Before writing the Dockerfile, verify a matching official Docker image tag actually exists**; if it does not, fall back to the newest tag that does and say which and why. Database: sqlite3, one compose service only. No implementation whatsoever: no models, no scaffolds, no auth. Existing files at the root must be left untouched.
>
> **Deliverable (the ONLY acceptance criterion)**: `docker compose up`, then `curl -w '%{http_code}' http://localhost:3000` returns 200 and the body is the stock Rails welcome page. You MUST actually run it and paste that curl output as proof. Do not report success without it.

### Stating the design, then asking for holes

The design was never outsourced. The prompt states the decision already taken, in domain terms, and closes by authorising the work unless the model can argue for something better:

> The market feed reads CoinGecko through three collaborators, each with one job. `HttpDataSource` performs the request and returns a `Result`; on failure it carries message, code, status and body, and it interprets nothing — a 429 is a status to it, never a meaning. `CacheDataSource` is cache-first: it judges freshness from the entry's own `cached_at` against a TTL, and serves a stale entry only when the caller's `serve_stale_if` decides that this particular error justifies it. The adapter is the only place allowed to know that 429 means rate limited. `AssetIndex` is the single entry point the controller sees. Proceed unless you have a better option — if you do, say it first.

Everything that decides the shape is already fixed: which collaborators exist, what each one is responsible for, and above all where a provider's representation stops being a provider's representation. The model is left with the code and with one opening — the final clause, which invites disagreement before the work rather than after it.

The difference matters because what comes back is judged, not applied. Of the five shapes the model proposed for the threshold metrics — the worked example below — four were rejected. When the model designed on its own initiative — it introduced a `measurement` field sitting next to `key`, both identifying the same metric — the redundancy was caught on review and the field was removed. Authority over the design stayed on the human side throughout; the model's job was to argue against a design that already existed and to write the code once it was settled.

## How the design was steered

Before any code, and before any prompt, the first question answered was which bounded contexts the application has. Three came out of it: **Market Feed**, which owns everything the dashboard is about; **Authorization**, which decides who may do what; and **Auditing**, which records what was done. Only once those boundaries were settled did entity design begin, context by context.

That decision is not documentation: it is the structure of the application. The three contexts are the three modules, and the split repeats in every layer — `app/models/market_feed`, `app/services/market_feed`, `app/repositories/market_feed`, `app/controllers/market_feed`, `app/views/market_feed`, and the same for `authorization` and `auditing`. A context boundary that only exists in a diagram is a suggestion; one that is a namespace is enforced by the language, and crossing it is something you have to type on purpose.

This project is written in a strongly domain-driven way, and the consequence is visible in the file tree: every concept that matters inside a context is an object, not a hash and not a loose primitive. `Asset`, `ConversionRate`, `PricePoint`, `CatalogEntry`, `Threshold`, `Metric` and `WatchlistItem` in Market Feed; `AccessToken` and `Permissions` in Authorization; `ActivityEntry` in Auditing. Several of them are not database tables at all — an `Asset` is assembled from an API response, a `Metric` is pure configuration — and that is the point: being a concept in the domain is what earns an object, not being a row.

The design was iterative, never a single upfront pass over the whole system. Each use case was designed in layer order — application first, then infrastructure, then domain — one file at a time, so every step was a chunk small enough to actually read. The point of that order is to build declaratively: everything is used before it is created. The application layer calls collaborators that do not exist yet, and each lower layer is then written to satisfy calls that are already there. Nothing is added "just in case", because a field nobody is calling for is a field that does not get written, and what actually needs modelling reveals itself while coding instead of being guessed up front.

Within each file the loop was the same: state the decision, let the model produce, measure the result against written conventions, correct. The conventions existed before the code, which is what made "this is wrong" a checkable claim instead of a matter of taste.

Review effort is not spread evenly across the layers, and deliberately so. It concentrates on the application layer — the orchestrators that embody a use case, such as `MarketFeed::AssetIndex` — and on the domain classes, because that is where a wrong decision is both expensive and invisible: nothing fails, the code simply models the wrong thing. Infrastructure is reviewed, but not line by line; an adapter or a data source has a narrow contract, and its failures tend to be loud. Presentation gets the least reading of all — in practice it is reviewed by using the application manually, which is the one place where looking at the screen tells you more than looking at the file.

Three rules carried most of the weight:

- **The domain is modelled with objects, not with configuration.** A literal holding the behaviour of three concepts is a switch statement wearing a hash's clothes.
- **Layers own their own knowledge.** Whoever holds the data answers questions about it; a consumer that reaches into another object's internals to compute something is in the wrong layer.
- **Names state what the thing is and what the method does.** A name that describes the technology, or a verb narrower than the real contract, is a defect even when the code is correct.

### Where the AI got the design wrong: a configuration hash standing in for domain objects

`MarketFeed::Threshold` began as an `ApplicationRecord` holding a frozen `KINDS` hash — three entries describing a UI label, a unit, a comparison direction and two default values — plus a `case` on the same identifier, in a separate private method, resolving how to measure each one. Adding a fourth threshold meant editing both, and nothing connected them.

It took five rounds to land, and the model was wrong in four of them:

1. **The first proposal was one class per kind.** Rejected: the three differed only in the values of their fields, and nothing else. Subclassing is for types that differ in fields, methods or validations — not for rows of data wearing class syntax.
2. **The single class arrived as a `Data.define`.** Rejected: value equality and immutability were never used, and a plain class with a keyword initializer says the same thing without the indirection.
3. **Measurement was implemented as `metric.measure(asset)` on the value object.** Rejected: a configuration object that sends messages to an `Asset` stops being configuration. The threshold is the one that decides; the threshold is the one that should ask.
4. **The measurement then used `public_send` with a method name held as a field.** Rejected: reflection hides the call graph from every search and fails at runtime instead of at the call site. An explicit `case` over the identifier says the truth, at the cost of one more place to edit.
5. **The persisted column was still called `kind`.** Renamed to `metric`, migration included. "Kind" names a Rails habit; "metric" names the concept the domain actually talks about.

What landed: `MarketFeed::Metric` as pure data, `MarketFeed::Metrics` as the single registry every consumer reads, and `Threshold` owning the comparison and the explicit dispatch. The measurements themselves moved onto `Asset`, which is the object that holds the numbers.

The trade-off was accepted knowingly, not discovered afterwards: a new metric now touches the registry and one branch of the `case`, and a missing branch colours nothing instead of raising.
