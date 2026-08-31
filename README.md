# ai-flow

Dotfiles for AI Driven Workflow.

A starting point: clone it as the base for a new project, enter the devshell,
then launch your agent from inside it.

## Usage

```sh
nix develop           # default shell (Claude Code)
nix develop .#claude  # the same shell, named explicitly
```

Entering the devshell first is how you get a properly provisioned agent
environment.

## Setup

Run these once per clone, from inside the devshell.

Nothing here is committed by the template. Plugin state lives outside the repo
and is recorded per project, and the OpenSpec scaffolding is generated output —
so the sequence has to be repeated on each machine and each clone.

### Claude Code

```sh
openspec init --tools claude                               # scaffold the spec workflow
claude plugin install code-review@claude-plugins-official
claude plugin install superpowers@claude-plugins-official
```

Verify with:

```sh
claude plugin list
```

Order matters: `openspec init` comes first, because `CLAUDE.md` refers to the
`/opsx:*` commands it generates.

Enabling a plugin and installing it are separate steps. An entry in
`enabledPlugins` that was never installed fails silently, so check the list
rather than assuming.

### Other vendors

Add a subsection here as each vendor's devshell is added, covering its OpenSpec
`--tools` target and how it installs the equivalent plugins.

## Layout

| Path         | Purpose                                                                  |
| ------------ | ------------------------------------------------------------------------ |
| `flake.nix`  | Devshell definitions — one shell per agent vendor, over a shared toolset. |
| `AGENTS.md`  | Shared agent instructions and the spec-driven workflow policy.            |
| `CLAUDE.md`  | An `@AGENTS.md` import plus Claude's OpenSpec command bindings.           |
| `.claude/`   | Claude-only config: plugins, skills, commands, hooks.                    |
| `openspec/`  | Spec-driven workflow config and change artifacts. Created by setup, not tracked here. |

## Agent instructions

`AGENTS.md` is the vendor-neutral convention read by most AI coding agents
(Codex, Copilot, Cursor, Gemini CLI, Aider, Zed, and others). Claude Code loads
`CLAUDE.md`, which imports it — so every agent works from one source and the two
files never drift.

The split follows one rule: **policy is portable, command names are not.**

- Workflow policy, and anything true of every agent → `AGENTS.md`
- Vendor command bindings and overrides → `CLAUDE.md`, below the import line

Keep both short. Their contents load into the agent's context on every session,
so anything written there carries a running token cost. Prefer exact commands
over prose.

`AGENTS.md` ends with a **Project conventions** section for exactly this:
setup steps, build / test / lint commands, code conventions, and constraints the
agent must respect. Everything above that heading is template-stable; the
section below it belongs to whoever works in the project.

## Plugins

These are the capabilities this template expects. Install commands are under
[Setup](#setup).

| Plugin        | Purpose                                                            |
| ------------- | ------------------------------------------------------------------ |
| `code-review` | Review a GitHub pull request.                                      |
| `superpowers` | Agentic skills framework — TDD, debugging, collaboration patterns. |

The two cover different moments. `code-review` operates on a pushed PR through
`gh`; the pre-commit review the workflow asks for comes from Superpowers'
`requesting-code-review` skill.

`.claude/settings.json` declares both under `enabledPlugins`, and they live in
`claude-plugins-official`, which is registered automatically — so there is no
marketplace to add.

## Spec-driven development

`openspec` drives the change workflow: explore an idea, propose a change, apply
it, archive it. The CLI ships in the devshell; `openspec init` generates the rest:

| Path                         | Contents                                                          |
| ---------------------------- | ----------------------------------------------------------------- |
| `openspec/config.yaml`       | Project context, artifact rules, operation guidance. Portable.     |
| `.claude/commands/opsx/`     | Slash commands, for the `claude` target.                           |
| `.claude/skills/openspec-*/` | The matching skills, which the agent can invoke itself.            |

That scaffolding is deliberately not committed here. It is generated output,
pinned to the OpenSpec version that produced it, and most of it serves a single
vendor — so the template documents the command instead of vendoring its results,
and `.gitignore` enforces that.

**If you are building a project from this template, un-ignore `openspec/`.** It
is ignored here only because the template has no changes of its own. In a real
project the specs and change artifacts under `openspec/` are the record of why
the code looks the way it does — they belong in history, and losing them means
the next session re-derives reasoning you already paid for. The generated
bindings under `.claude/` can stay ignored; `openspec init` recreates them.

Change artifacts accumulate under `openspec/`. Refresh generated files after an
upgrade with `openspec update`.

### Workflow routing

`AGENTS.md` reduces the workflow to eight numbered stages plus a table saying
which stages each kind of work runs. Stages are written once; flows reference
them by number. An earlier draft spelled out a separate step list per flow,
which restated the same TDD and commit rules three times and let them drift.

OpenSpec owns planning end to end. Well-defined work opens at
`openspec-propose`; ill-defined work opens at `openspec-explore` and proposes
afterwards. Superpowers is left with execution — debugging, worktrees, TDD,
review, integration.

Greenfield work is the same flow with every delta marked ADDED. Resist one giant
change: a change that never finishes never archives.

Four ordering decisions, each with a reason:

- **Worktree before propose.** OpenSpec performs no git operations, and a fresh
  worktree contains only committed files. Creating it late leaves artifacts in
  one checkout and code in another, forcing a manual copy. Creating it first
  keeps `main` untouched and needs no merge-back branch.
- **The proposal is the only record.** An earlier draft opened with Superpowers'
  `brainstorming` and wrote the session to `brainstorm.md` afterwards. Dropping
  brainstorming removed both the file and the seam it sat on — the proposal now
  carries the reasoning, so it has to stand on its own rather than assume a
  conversation nobody kept.
- **Stage 1 states its own exit condition.** `openspec-explore` describes itself
  as "a stance, not a workflow" with "no mandatory outputs", and offers to
  recommend a path only *if asked* — so `AGENTS.md` asks. Requiring decisions
  with 2–4 options gives stage 1 a definition of done and hands stage 3
  something settled to propose from. The durable home for that shape is
  `openspec/config.yaml`'s `rules` for `design.md`, which is where explore's own
  capture table sends design decisions; rules bind only when an artifact is
  written, so the prose rule covers the conversational case.
- **`writing-plans` excluded.** It duplicates `tasks.md`, whose checkboxes
  `openspec list`, `status`, and `archive` parse — merging micro-steps in counts
  examples as real work and reports a finished change as incomplete.
- **Shared stages are written for every flow that reaches them.** Stages 3 and 7
  are the only proposal-only ones. Stages 4 and 8 each silently assumed a change
  directory at one point, which broke the bug-fix flow: it arrives at stage 4
  having skipped stage 3, so there is no `tasks.md` to loop over.

#### Skills do not fire on their own

Superpowers skills activate only when invoked by name. Prose in `AGENTS.md`
loads once at session start and, by the time implementation begins, sits under
thousands of tokens of working context. The built-in apply instruction is two
lines — *read context files, work through pending tasks, mark complete as you
go* — with no mention of TDD, delivered fresh as apply begins. It wins on
recency and specificity. Tested: the same TDD instruction failed twice from
`AGENTS.md` and worked when spoken at apply time.

Three defences, weakest to strongest:

1. **Imperatives at the point of use.** Every stage leads with a verb and names
   the skill in full — `superpowers:test-driven-development`, never bare.
   Phrasing matters at the margin: lead with the imperative, because a rule
   opening "skills do NOT activate on their own" reads as one more prohibition
   in a file where every capitalised NOT is one.
2. **A re-read at each boundary.** The file cannot re-inject itself, so it
   instructs a re-read at a point the loop already stops at.
3. **Dispatch.** Stage 4 sends each task group to a fresh subagent. Its prompt
   is written at the moment of dispatch — exactly the condition the test above
   found to work, and the only one of the three that does not depend on an
   hour-old file still carrying weight.

#### Skills overrun their handoff

Superpowers skills are built to run end to end. Each ends by doing the next
thing — right when the skill is the whole workflow, wrong when it is one step
inside another:

| Skill | Its last step | What it breaks |
|---|---|---|
| `receiving-code-review` | implements the feedback | bypasses `openspec-update-change`'s coherence pass |
| `subagent-driven-development` | sets up a worktree, dispatches the final review, then calls `finishing-a-development-branch` | swallows stages 2, 5 and 6, and expects a Superpowers plan file and ledger rather than `tasks.md` |

Each is handled by naming the stopping point, or by not adopting the skill at
all. `subagent-driven-development` is the second case: `AGENTS.md` dispatches per
task group itself, keeping OpenSpec as the artifact owner. That works precisely
because the artifacts are on disk — a cold subagent reads the proposal and
`tasks.md` for itself, so there is no session context to reconstruct in its
prompt.

Before adopting another skill, read its final step and ask whether that is where
this workflow wants it to stop.

#### Reviews

`requesting-code-review` dispatches its own reviewer subagent and states that it
never inherits the caller's history, so it needs no extra wrapping. It runs once,
over the whole branch.

Per-group review was tried and reverted. Dispatching implementers made the
skill's "after each task" guidance applicable — the coordinator genuinely no
longer sees the work — but measured on a four-group change it turned five review
passes into the largest single cost of the run. Its value is catching a bad
pattern before it propagates into later groups, which is worth little when few
groups remain. Past roughly eight groups that trade flips; below it, the branch
review catches the same things later and once.

#### If prose is not enough

Two published OpenSpec schemas inject instructions at each artifact step:
[`superpowers-bridge`](https://github.com/JiangWay/openspec-schemas/tree/main/superpowers-bridge)
and [`superspec`](https://github.com/danielhanold/superspec).

The cost is a dependency adopted whole, pinning its own baselines and riding
`openspec schema` while it is still experimental. Both also route TDD through
`subagent-driven-development`'s transitive activation, which no longer exists in
Superpowers 6.3.0 — adopting either as-is would not fix a dormant TDD.

The channel still unused is `openspec/config.yaml`, the portable half of the
generated output, which governs how artifacts get written. Anything it can emit
into the `tasks.md` preamble arrives at apply time through OpenSpec's own
machinery — no recency problem, no fork.

### Per-vendor targets

`--tools` takes `all`, `none`, or a comma-separated list, and covers most agents
(claude, codex, cursor, gemini, github-copilot, zed, and more). Each target
writes into that vendor's own directory.

There is also a vendor-neutral `agents` target that writes shared skills to
`.agents/skills/`. It generates no slash commands, so where a vendor target
exists it is usually the richer option.

`openspec/config.yaml` is the portable half of the generated output — put
project context and artifact rules there rather than duplicating them per
vendor. It covers how specs get written; `AGENTS.md` covers everything else.

## Adding another agent

Define a shell in `flake.nix` alongside `claude` and expose it in the attrset:

```nix
codex = pkgs.mkShell { packages = common ++ [ pkgs.codex ]; };
```

Then re-run setup with the extra target, and add its subsection under
[Setup](#setup):

```sh
openspec init --tools claude,codex
```

Vendor-specific config stays in that vendor's own directory, the way `.claude/`
does. Only genuinely portable content belongs in `AGENTS.md`.
