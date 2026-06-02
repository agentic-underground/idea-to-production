# Slice ledger

A one-line, append-only record per shipped slice. Lets a fresh agent reconstruct history.

```
SLICE-00 · full-Rust hello-world vertical slice · STORY:greets_a_name · perf:baseline · shipped:2026-06-01
SLICE-01 · deploy web+api to Vercel · STORY:api_greet_responds_in_prod · perf:+0ms · shipped:TBD
SLICE-NN · <value sentence> · STORY:<name> · perf:<+/-Δ vs baseline> · shipped:<date>
```
