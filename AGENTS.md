## Spec-driven workflow

- Every new feature starts with `openspec-propose` — or with `openspec-explore`
  first, when the shape of the work is not clear yet. OpenSpec owns the planning
  phase: do NOT use Superpowers `brainstorming` or `writing-plans`, and do not
  let `using-superpowers` route into them. Superpowers still owns execution.
- Implementation follows TDD: write the failing test first, then the code.
  Delete any implementation written before its test.
- Run Superpowers' `requesting-code-review` before every commit, and work in an
  isolated git worktree.
- A change is not finished until it is archived. Never leave one un-archived —
  the next session will re-read the stale spec and redo completed work.
