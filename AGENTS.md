## Spec-driven workflow

OpenSpec owns the artifacts, Superpowers owns execution. Planning is OpenSpec's
end to end; `tasks.md` is the plan, so NEVER invoke `superpowers:writing-plans`.

Skills do not fire on their own. Each one below is a Skill-tool call made by
full name — `superpowers:test-driven-development`, never bare.

**Before answering any request that touches code, find its row and run those
stages in order — before clarifying questions, before reading files.**

| Work | Stages | Opens with |
| ---- | ------ | ---------- |
| New capability, breaking or architectural change — unclear | 1–7 | `openspec-explore` |
| Same, but well defined | 2–7 | `openspec-propose` |
| Bug fix, refactor, config, test backfill | 1, 2, 4, 5, 6 | `superpowers:systematic-debugging` |
| PR change requests on a live change | 8 → 4 → 5 → 6 → 7 | `superpowers:receiving-code-review` |
| Typos, comments, docs — no code change | none | make it, show the diff |

Bug work that grows — new behaviour, a contract change, a multi-file redesign —
escalates mid-flight to stage 3, or stage 1 if the shape is still unclear.
One-line fixes never escalate.

### Stages

1. **Frame.** Invoke the skill in your row, in conversation. Skip when the work
   is already well defined.
2. **Isolate.** Invoke `superpowers:using-git-worktrees`. NEVER work on `main`.
3. **Propose.** Invoke `openspec-propose`. It writes the change directory, and
   it is the only record of how the work was decided — make it stand alone.
4. **Implement.** Work runs in fresh subagents — never pass them this
   session's history. Each gets the change directory path and its unit's text;
   it reads the artifacts itself.
   - After stage 3: dispatch one subagent per `## ` group in `tasks.md`,
     sequentially — later groups build on earlier ones. It invokes
     `superpowers:test-driven-development` per checkbox (failing test first,
     delete any implementation written before its test), runs the tests, and
     commits. Mark the checkboxes from its report, then run stage 5 over that
     group before dispatching the next. Stop at every boundary even though
     `openspec-apply-change` wants to continue — it arrives fresher than this
     file and mentions none of the above.
   - Without a proposal: the fix is a single unit. Implement it directly under
     `superpowers:test-driven-development`; dispatching costs more than it
     saves.
5. **Review.** Invoke `superpowers:requesting-code-review`, which dispatches its
   own reviewer — over each group's commits during stage 4, and once over the
   whole branch after it.
6. **Integrate.** Push, PR, and merge ALWAYS wait for the user; commits do not.
   Then invoke `superpowers:finishing-a-development-branch`.
7. **Archive.** Invoke `openspec-archive-change`. ALWAYS last, NEVER before 5
   and 6.
8. **Revise.** Invoke `superpowers:receiving-code-review` to evaluate — do NOT
   let it implement; its last step writes the fix. Carry accepted feedback in
   with `openspec-update-change`, NEVER by hand-editing `tasks.md`; without a
   proposal, apply it directly. Then re-enter stage 4.

Reasoning lives in README "Workflow routing".

## Project conventions

Everything above is template-stable. Project-specific guidance — coding style,
dos and don'ts, build and test commands — goes below.

<!-- Add project-specific guidance here. -->
