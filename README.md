# Real-Time Financial Dashboard with Dynamic RBAC

A crypto market dashboard backed by the CoinGecko API, with role-based access control enforced on both the server and the UI.

## Running it

```bash
cp .env.example .env
docker compose up -d
```

If you have `make` installed, `make up` and `make down` are the same two commands.

The app is served at <http://localhost:3000>. `docker compose down` stops it. The container runs `db:prepare` on boot, which migrates and — on a database being created for the first time — loads the seeds, so there is no separate setup step.

`COINGECKO_API_KEY` is optional. Without it the public rate limit applies, which is low enough that a page load can hit a 429 — the cache absorbs it, but the first load of the day is slower. The demo key raises the limit comfortably.

## Signing in

There is no password. Seeds create one user per role:

| Email | Role |
| --- | --- |
| `viewer@example.com` | Viewer |
| `trader@example.com` | Trader |
| `admin@example.com` | Admin |

The **Switch user** button in the sidebar opens the role switcher and swaps the authenticated user immediately. The session is an `access_token` cookie carrying the user id only — the role is read from the database on every request, so a demoted user loses access on their next click rather than when a token expires.

## What each role can do

| | Viewer | Trader | Admin |
| --- | --- | --- | --- |
| Market feed | yes | yes | yes |
| Own watchlist | no | yes | yes |
| Thresholds | no | no | yes |
| Activity log | no | no | yes |

Enforcement runs in two places. The server declares a permission per controller action and denies anything undeclared, answering `403` to a signed-in user without the permission and `401` — or a redirect to the sign-in page, for HTML — to an anonymous one. The UI hides what the current role cannot reach, so the sidebar, the watchlist stars and the threshold forms appear only for the roles that own them.

## Tests

```bash
docker compose exec web bin/rails test
```

CI additionally runs RuboCop, Brakeman and an importmap audit.

## Interpretations

Where the assignment left room, these are the readings taken:

- **"Edit a watchlist item"** — a watchlist item is a user/asset pair with nothing else to change, so editing one is adding and removing. The routes expose `index`, `create` and `destroy`, and no edit screen exists.
- **Thresholds are global and are not applied by default.** Only persisted rows colour the table; the defaults in `MarketFeed::Metrics` prefill the admin form and nothing else. An untouched threshold therefore colours nothing.
- **"24h Volatility"** is read as the day's range, `(high − low) / low`, not as a standard deviation of returns.
- **Audit entries record the actor, not the owner of the subject.** An admin editing someone else's data is logged as the admin.
- **Rate limiting is handled cache-first, not API-first.** A page load reads from the cache and only reaches CoinGecko for entries past their TTL; on a 429 the stale entry is served instead of failing. Fetching first and caching afterwards would spend six requests per load and provoke the 429 it is meant to survive.
