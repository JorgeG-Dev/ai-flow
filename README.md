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

## Sandbox

`.claude/settings.json` turns on Claude Code's sandbox, so the agent runs every
Bash command under bubblewrap and a seccomp filter instead of asking permission
each time:

```json
"sandbox": {
  "enabled": true,
  "autoAllowBashIfSandboxed": true,
  "allowUnsandboxedCommands": false
}
```

The trade is deliberate — the agent gets a quiet, wide working surface, and the
blast radius stays inside the project. It costs two things worth knowing.

### Nix is unavailable to the agent

The seccomp filter blocks `socket(AF_UNIX, ...)`, and the Nix store is reached
through a daemon socket. Every store operation fails from inside a session:

```
error: cannot create Unix domain socket: Operation not permitted
```

`nix develop`, `nix build`, `nix run`, and `nix flake update` are all affected.
Pure evaluation (`nix eval --expr '1+1'`) still works, having never touched the
store.

This leaves the documented workflow intact: you enter the devshell first and the
agent inherits it. What it prevents is the agent picking up a tool it just added
to `flake.nix`. Add the package, then relaunch the agent from a fresh
`nix develop`.

To lift the restriction, add to the `sandbox` block:

```json
"network": { "allowAllUnixSockets": true }
```

Linux offers nothing narrower. `allowUnixSockets` takes a path list, but seccomp
cannot match on paths, so that setting is macOS-only and silently ignored here.
Enabling this grants access to **every** Unix socket the user can reach —
`docker.sock`, `ssh-agent`, and dbus among them. Weigh that against a relaunch.

### Git config is masked

`.gitconfig` and `.gitmodules` are bind-mounted to `/dev/null`, so the agent can
neither read nor write them, whether or not the files exist. Git reports
`Permission denied`; libgit2 — which Nix uses to fetch `git+file://` flake
inputs — reports the same condition as `'.gitmodules' is locked`. Submodule
commands are unavailable to the agent.

`sandbox.filesystem.allowGitConfig: true` restores access. Leave it off unless
the project actually uses submodules: a writable git config lets an agent set
aliases, a pager, or an `ext::` submodule URL that executes the next time **you**
run git.

## Layout

| Path         | Purpose                                                                  |
| ------------ | ------------------------------------------------------------------------ |
| `flake.nix`  | Devshell definitions — one shell per agent vendor, over a shared toolset. |
| `AGENTS.md`  | Shared agent instructions and the spec-driven workflow policy.            |
| `CLAUDE.md`  | An `@AGENTS.md` import plus Claude's OpenSpec command bindings.           |
| `.claude/`   | Claude-only config: sandbox settings, plugins, skills, commands, hooks.   |
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

Worth adding to `AGENTS.md` once there is a real project here: setup steps,
build / test / lint commands, code conventions, and constraints the agent must
respect.

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

OpenSpec and Superpowers both want the planning phase — Superpowers'
`brainstorming` skill asserts it must run before any creative work, and OpenSpec
expects the proposal step to own it.

`AGENTS.md` settles it by nesting rather than choosing. OpenSpec owns the
artifacts and their order; the Superpowers planning skills run *inside* that
flow with their output paths overridden. `brainstorming` writes `brainstorm.md`
and `writing-plans` writes `plan.md`, both into the change directory rather than
their default `docs/superpowers/`. Both skills document that their output
location is overridable by user preference, so this costs no fork and no patch —
a line in `AGENTS.md` is the override.

Keep those two as separate files. OpenSpec does not track them, but it parses
`tasks.md` checkboxes to report progress for `openspec list`, `status`, and
`archive`. Folding plan micro-steps into `tasks.md` counts example checkboxes —
including ones inside fenced code blocks — as real work, so a finished change
reports as incomplete and archival stalls.

Two rules ride along:

- **Ceremony scales with risk.** Three tiers, chosen by two questions —
  does it change how the code behaves, and if not, does it touch code at all?
  Behavior changes (bug fixes included) get the full change: proposal,
  worktree, TDD, `requesting-code-review`, archive. Code or build config with
  no behavior change — refactors, test backfill, dependency bumps, lint rules —
  gets `requesting-code-review` and a commit, no proposal and no worktree.
  Prose-only edits are just made and shown as a diff. Committing and opening
  PRs waits for the user in every tier, and no tier works directly on `main` —
  every one gets a branch. The worktree is an escalation for long-running
  feature work, not the only form of isolation.
- **Converged discussions get promoted, never assumed.** When a design
  conversation settles, the agent offers to open a change and waits for a yes.

That policy lives in `AGENTS.md` rather than `CLAUDE.md` because Superpowers
exists for more than one agent, so the rule holds wherever it is read. Only the
entry points are vendor-specific: those live in each vendor's own file, and the
current names come from the OpenSpec docs rather than being restated here.

Edits to either file take effect at the next session start, not immediately.

#### Prior art

Two published OpenSpec schemas solve this same overlap by vendoring a custom
schema: [`superpowers-bridge`](https://github.com/JiangWay/openspec-schemas/tree/main/superpowers-bridge)
and [`superspec`](https://github.com/danielhanold/superspec), the latter a
repackaging of the former's origin. Both are worth reading, and both make
`brainstorm.md` and `plan.md` first-class tracked artifacts, which the prose
rules above cannot.

This template deliberately takes the rules and skips the dependency: a schema
bundle is adopted whole, pins its own OpenSpec and Superpowers baselines, and
rides `openspec schema`, still marked experimental. That is a poor thing to hand
every downstream clone. Adopt one directly if you want the full artifact
pipeline.

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
