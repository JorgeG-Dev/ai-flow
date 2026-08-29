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

## Layout

| Path         | Purpose                                                                  |
| ------------ | ------------------------------------------------------------------------ |
| `flake.nix`  | Devshell definitions — one shell per agent vendor, over a shared toolset. |
| `AGENTS.md`  | Shared, vendor-neutral agent instructions. Empty by default.              |
| `CLAUDE.md`  | A single `@AGENTS.md` import so Claude Code reads the shared file.        |
| `.claude/`   | Claude-only config: sandbox settings, plugins, skills, subagents, hooks.  |
| `openspec/`  | Spec-driven workflow config and artifacts. Created by `openspec init`.    |

## Agent instructions

`AGENTS.md` is the vendor-neutral convention read by most AI coding agents
(Codex, Copilot, Cursor, Gemini CLI, Aider, Zed, and others). Claude Code loads
`CLAUDE.md`, which holds nothing but an `@AGENTS.md` import — so every agent
works from one source and the two files never drift.

- Shared instructions → `AGENTS.md`
- Claude-only instructions → `CLAUDE.md`, below the import line

Both ship empty on purpose. Their contents load into the agent's context on
every session, so anything written there carries a running token cost. Keep them
short and factual, and prefer exact commands over prose.

Worth adding to `AGENTS.md` once there is a real project here: setup steps,
build / test / lint commands, code conventions, and constraints the agent must
respect.

## Plugins

These are the capabilities this template expects. Plugin state is stored outside
the repo and recorded per project, so cloning installs nothing — the install
step has to be repeated on each machine and each clone.

| Plugin        | Purpose                                                            |
| ------------- | ------------------------------------------------------------------ |
| `code-review` | Code review and security review workflows.                         |
| `superpowers` | Agentic skills framework — TDD, debugging, collaboration patterns. |

The capabilities above are the portable part. How you install them is not, so
each vendor gets its own instructions below.

### Claude Code

`.claude/settings.json` already declares these under `enabledPlugins`, and both
live in `claude-plugins-official`, which is registered automatically — so
there is no marketplace to add. Install them with:

```sh
claude plugin install code-review@claude-plugins-official
claude plugin install superpowers@claude-plugins-official
```

Verify with:

```sh
claude plugin list
```

Enabling a plugin and installing it are separate steps. An entry in
`enabledPlugins` that was never installed fails silently, so check the list
rather than assuming.

### Other vendors

Add a subsection here as each vendor's devshell is added, covering how that tool
installs the equivalent capabilities.

## Spec-driven development

`openspec` drives the change workflow: propose a change, apply it, archive it.
The CLI ships in the devshell, but it is a generator rather than a plugin — each
project is initialized once, and the files it writes are committed.

This template ships uninitialized on purpose, since the artifacts are specific
to whatever project you build here.

```sh
openspec init --tools claude
```

That writes:

| Path                         | Contents                                                          |
| ---------------------------- | ----------------------------------------------------------------- |
| `openspec/config.yaml`       | Project context, artifact rules, operation guidance. Portable.     |
| `.claude/commands/opsx/`     | Slash commands — `/opsx:propose`, `/opsx:apply`, `/opsx:archive`.  |
| `.claude/skills/openspec-*/` | The matching skills.                                               |

Start a change with `/opsx:propose "your idea"`.

### Per-vendor targets

`--tools` takes `all`, `none`, or a comma-separated list, and covers most agents
(claude, codex, cursor, gemini, github-copilot, zed, and more). Re-run it with
the extra target as each vendor's devshell is added:

```sh
openspec init --tools claude,codex
openspec update                      # refresh generated files after upgrades
```

There is also a vendor-neutral `agents` target that writes shared skills to
`.agents/skills/` rather than a vendor directory. It generates no slash
commands, so on Claude the vendor target is the richer option.

Generated files land in each vendor's own directory, matching the rule used
everywhere else here. `openspec/config.yaml` is the portable half — put project
context and artifact rules there rather than duplicating them per vendor. It
covers how specs get written; `AGENTS.md` covers everything else.

## Adding another agent

Define a shell in `flake.nix` alongside `claude` and expose it in the attrset:

```nix
codex = pkgs.mkShell { packages = common ++ [ pkgs.codex ]; };
```

Vendor-specific config stays in that vendor's own directory, the way `.claude/`
does. Only genuinely portable content belongs in `AGENTS.md`.
