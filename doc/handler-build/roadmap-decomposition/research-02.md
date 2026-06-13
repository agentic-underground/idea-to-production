# Research Axis 2: Dependency-Graph Extraction & Parallelization

## Core Algorithms

- **Kahn's Algorithm (BFS-based topological sort)**: Industry standard for DAG ordering. Process nodes with zero in-degree, remove iteratively, detect cycles when remaining edges exist post-completion. Stratifies graph into generations where each level's dependencies satisfy from prior levels.
- **DFS-based topological sort**: Stack-based alternative; trades space for potential simpler iteration patterns in some contexts.
- **Strongly Connected Component (SCC) detection (Kosaraju's/Tarjan's)**: For breaking circular dependencies—identify feedback loops, segment into islands, mark highest-probability non-rerun task as break point.

## Cycle Detection & Validation

- **Early detection required**: Validate dependency graph before execution; circular/missing dependencies must error loudly at decomposition time, not runtime.
- **Algorithm**: After topological sort completes, remaining edge count > 0 signals cycle. For fine-grained SCC analysis, apply Kosaraju's algorithm to identify isolated cyclic components.
- **Common failure mode**: Circular dependencies (A→B→C→A) block all work; detecting early saves cost.

## Atomic Task Decomposition

- **Granularity principle**: Cannot be meaningfully subdivided without losing value. Indivisibility ≠ tiny—prefer vertical slices that ship complete, working features vs. multi-task micro-deliverables with zero intermediate value.
- **Verification**: Each task must have objectively checkable success criteria; avoid "eventually consistent" or speculative completion markers.
- **Hierarchy depth**: 2-3 decomposition levels optimal; deeper hierarchies introduce coordination overhead, shallower leaves jobs intractable.
- **Dependency minimization**: Design subtasks to operate on different files/components; shared state requests are red flags.

## Parallelization Detection & Maximization

- **Three decomposition patterns**:
  - **Sequential**: Strict ordering; each output feeds next input.
  - **Parallel**: Completely independent subtasks; no sibling data coupling.
  - **Hybrid**: Sequential phases containing parallel branches within each.
- **Detection heuristic**: If subtask produces output consumed by no other subtask, it's parallelizable. If input required from non-parent, sequential dependency exists.
- **Shared infrastructure scanning**: Scan all subtasks for common dependencies (shared config, APIs, databases, build tools). Group into common "setup" or "teardown" phases to minimize redundant work and detect blocker resources.

## Tooling & Implementation

- **NetworkX (Python)**: Canonical library for DAG analysis. Functions: `topological_sort()` (linear ordering), `topological_generations()` (stratified levels), cycle detection built-in.
- **GraphQL/REST for dependency extraction**: Many CI/CD systems expose dependency metadata via APIs (GitHub Actions workflows, Terraform plans, Makefiles). Parse to adjacency lists or edge lists before applying sort.
- **Common serialization**: Adjacency list or edge list (JSON arrays) for portability; GraphML/DOT for visualization validation.

## Testing & Validation

- **Unit tests**: (1) Acyclic graphs produce valid topological orderings; (2) Cyclic graphs error with cycle report; (3) Generations match expected stratification; (4) Edge removal during Kahn's iteration preserves correctness.
- **Integration tests**: Real roadmap items → dependency extraction → topological sort → parallelization report. Spot-check 3-5 complex items (multi-phase features, refactorings with cross-cutting concerns).
- **Failure mode tests**: Circular deps, missing dependencies, isolated nodes, disconnected subgraphs, self-loops.
- **Validation checklist**:
  - No item has unspecified predecessor.
  - All inferred parallelizable pairs have zero shared infrastructure.
  - Generations form strict levels (no intra-level edges).
  - Execution cost of sorted order ≤ original backlog (no redundant ordering imposed).

## Known Pitfalls

- **Over-fragmentation**: Breaking work too finely creates coordination tax; re-evaluate if decomposition depth > 3 or if predecessor count per task > 2.
- **Implicit dependencies**: Unwritten constraints (e.g., "feature X must ship before marketing launch") must be explicitly encoded in graph; inference from titles/descriptions alone is error-prone.
- **Shared infrastructure blindness**: Multiple tasks requesting same API endpoint, shared database, or build tool create false parallelization claims; must scan for overlapping resource footprints.
- **Cyclic tolerance in real systems**: Some teams accept backlog cycles (e.g., feature flag gates that re-enable predecessor work). Must explicitly mark as acceptable cycles vs. errors; default is acyclic.

## Source URLs

- [NetworkX DAG algorithms guide](https://networkx.org/nx-guides/content/algorithms/dag/index.html)
- [Topological Sorting in DAGs: Algorithms & Practical Guide (Upgrad)](https://www.upgrad.com/blog/topological-sorting-in-dags/)
- [Topological Sorting Explained: Dependency Resolution (Medium)](https://medium.com/@amit.anjani89/topological-sorting-explained-a-step-by-step-guide-for-dependency-resolution-1a6af382b065)
- [GeeksforGeeks Topological Sorting](https://www.geeksforgeeks.org/dsa/topological-sorting/)
- [Task Decomposition Best Practices (Oneuptime, Jan 2026)](https://oneuptime.com/blog/post/2026-01-30-task-decomposition/view)
- [Cyclic Interdependencies in Critical Infrastructures (ResearchGate)](https://www.researchgate.net/publication/220816527_An_Analysis_of_Cyclical_Interdependencies_in_Critical_Infrastructures)
- [Tracking and Controlling Microservice Dependencies (ACM Queue)](https://queue.acm.org/detail.cfm?id=3277541)
