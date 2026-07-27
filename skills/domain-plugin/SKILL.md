---
name: domain-plugin
description: Domain reference for building a Claude Code plugin or marketplace. Open it during design and during development. It carries the version-pin policy, the shape of marketplace.json, how to run validate, and where components live.
---
# domain-plugin — plugin management domain reference

## Scope
How to build and ship a Claude Code plugin or marketplace.

## Entries
- **Watch the version pin** — while the plugin is under active development, leave `version` **empty**
  in `plugin.json` so updates keep following the commit SHA automatically. Setting a version switches
  updating to a version-string comparison, and from then on a new commit never reaches users unless
  someone bumps that value. The official documentation recommends this explicitly
  ([Version management in the plugins
  reference](https://code.claude.com/docs/en/plugins-reference#version-management)). `claude plugin
  validate` does warn about the absent version, but that warning is a cosmetic problem while a broken
  update path is the real damage, so accept the warning.
- **`marketplace.json`** — put the top-level `name`, `description`, `owner`, and `plugins[]` in
  `.claude-plugin/marketplace.json`. When the repository root is itself the plugin, point at it with
  `source: "./"`.
- **`validate`** — verify with `claude plugin validate ./`. `--strict` treats even warnings as
  failures, so in a repository that accepts the version warning under the pin policy above, a failing
  `--strict` is the normal outcome; confirm the pass without `--strict` instead.
- **Where components live** — put them in `agents/`, `skills/`, `commands/`, and `hooks/hooks.json`.
  A `CLAUDE.md` at the plugin root is not loaded as context.
