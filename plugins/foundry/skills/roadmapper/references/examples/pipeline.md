# TaskFlow pipeline (v2)

## Pick rule
Items are sorted ASCENDING by order; the engine pulls the first `available` row that is the top row or
immediately below a `completed` row. State lives HERE, not in the epic files.

| order | epic | state | constructs | branch |
| --- | --- | --- | --- | --- |
| `0001` | [EPIC_0001.md](./EPIC_0001.md) | `available` | core task CRUD (3 plans) | `pipeline/0001-task-core` |
