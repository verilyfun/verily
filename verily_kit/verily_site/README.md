# verily_site

verily.fun, the landing page. It deploys on its own, separate from the app. The output is a folder of static files that any CDN or bucket can serve: no server, no JavaScript, and no requests to anyone else.

The page uses leptos HTML for its structure and leptoskit for its ink. The hand-drawn maps, jars, stamps, ticks, and highlights are Skribble components (`skribble_leptoskit`), rendered ahead of time by leptoskit's web renderer. Their entry and scroll motion is leptoskit `Motion`, which runs as plain CSS and stops under reduced motion. The mark is the geometry exported to `brand/verily-mark.svg`, and a test keeps the two identical.

```sh
devenv shell site:serve           # render to verily_kit/dist/site and serve on :8183
devenv shell site:build out/dir   # render somewhere else
cargo test -p verily_site         # structure, links, privacy, motion, colours, size
```

The links come from the environment at build time:

| Variable               | Default                  | What it sets                           |
| ---------------------- | ------------------------ | -------------------------------------- |
| `VERILY_SITE_ORIGIN`   | `https://verily.fun`     | canonical, Open Graph, robots, sitemap |
| `VERILY_APP_URL`       | `https://app.verily.fun` | every "Open Verily" button             |
| `VERILY_CONTACT_EMAIL` | `hello@verily.fun`       | the footer's address                   |

Colours live in `src/brand.rs` as tokens. `src/site.css` uses only `var(--…)`, and a test rejects a raw colour there. The fonts are Skribble's Recursive faces (`skribble_font_recursive`), subset to Latin as woff2 under `assets/fonts`.
