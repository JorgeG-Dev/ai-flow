@AGENTS.md

## OpenSpec bindings (Claude Code)

`openspec init --tools claude` generates a slash command and a skill per
workflow. You type the command; the agent invokes the skill.

| Workflow | Command | Skill |
| -------- | ------- | ----- |
| Propose | `/opsx:propose` | `openspec-propose` |
| Explore | `/opsx:explore` | `openspec-explore` |
| Apply | `/opsx:apply` | `openspec-apply-change` |
| Archive | `/opsx:archive` | `openspec-archive-change` |
| Sync | `/opsx:sync` | `openspec-sync-specs` |
| Update | `/opsx:update` | `openspec-update-change` |

These six are the default profile. `new`, `continue`, `ff`, `verify`, and
`bulk-archive` also ship — enable them with `openspec config profile`.
