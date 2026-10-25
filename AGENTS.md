# AGENTS.md

Guidance for AI coding agents working in this repository.
Claude Code reads `CLAUDE.md`, which carries the same text; when you change one, change the other.

## What this repo is

TechTrip AI's Claude Code–specific plugins, one per directory under `plugins/`. Each is
self-contained: its own `.claude-plugin/plugin.json`, README, CHANGELOG, version, and
`skills/<skill>/SKILL.md` files invoked as `/<plugin>:<skill>`. Users install from the public
catalog `TechTripAi/TechTrip-AI-plugins`, whose entries point here with `git-subdir` sources;
this repo's own `.claude-plugin/marketplace.json` exists only so a checkout loads in place
during development.

The rule for new work (catalog ADR-003): small and Claude-only goes in `plugins/` here;
anything with an installer, tests, harness templates, or an audience beyond Claude Code gets
its own repository and a `github` entry in the catalog.

There is no build, no package manager, no test runner and no linter. Bundled scripts must run
on the Python 3.9+ / shell that ships with macOS with the standard library only; do not add
dependencies. `bash scripts/check.sh` is the health check; run it before every commit.

## Commands

```bash
# Load a plugin into a session without installing it, then /reload-plugins after edits.
claude --plugin-dir ./plugins/claude-sessions

# Or register the checkout as a marketplace once (loads in place, no version bump needed)
claude plugin marketplace add .
claude plugin install claude-sessions@techtrip-claude-plugins

# Run a bundled script directly
python3 plugins/claude-sessions/scripts/sessions.py --help
python3 plugins/claude-sessions/scripts/sessions.py list --grep "text" --since 7d --json

# Health check and manifest validation
bash scripts/check.sh
claude plugin validate .
```

Skills are iterated with Anthropic's `skill-creator` plugin: each skill keeps its test prompts
in `skills/<skill>/evals/evals.json`, run with and without the skill, compare, adjust.

## Releasing

The plugin's `plugins/<name>/.claude-plugin/plugin.json` is the version of record. To release:

1. Bump `version` there, add a dated heading to `plugins/<name>/CHANGELOG.md`, and set the same
   version on the plugin's entry in this repo's `.claude-plugin/marketplace.json`.
2. `bash scripts/check.sh` (it fails on a version mismatch). Commit locally with a plain
   message, no attribution lines. The owner pushes.
3. **Then update the catalog:** in `TechTripAi/TechTrip-AI-plugins`, set the entry's
   `version` to the same string and push. Claude Code detects updates from `plugin.json`
   first and the entry second; a mismatch is a bug, and the catalog's `check.sh` reports it.

## Conventions every plugin here must follow

Promised in the README, so a plugin that breaks one needs the README changed too.

- **A brain-dump plus one worker skill per deliverable.** A `brain-dump` skill (teacher:
  menu-driven, re-runnable, `allowed-tools: Read`, never runs the workers or touches files on
  the user's behalf) and one or more worker skills whose `description` is a long list of
  plain-language trigger phrases. Add a new worker when the deliverable differs; add a flag
  on the shared script when it is only a filter over the same output.
- **Read-only, local-only by default.** Scripts read files and print. Anything that writes,
  changes settings, or sends data off the machine is stated in that plugin's README and asks
  first.
- **Copyable values are always complete.** Session ids, paths, URLs and commands are printed
  in full wherever they appear, tables included; never trimmed, never cut to a prefix. Only
  descriptive text may be trimmed, marked with `…`.
- **Advise, never install.** Preflight (`doctor`) and skill text tell the user what to install
  per OS; nothing runs installers.
- **Cross-platform means POSIX plus Windows branches.** Use the plugin's `pid_alive()` and
  `shell_quote()` / `cd_then()` helpers rather than `os.kill(pid, 0)` or hand-built quoting.
  Windows is untested until CI covers it, so READMEs claim only macOS and Linux.
- **One shared script per plugin, addressed relative to the skill directory.** Scripts and
  references live at the plugin root; SKILL.md refers to `<skill-dir>/../../scripts/...`.
  Never hardcode an install path.
- **brain-dump tone rules:** label every block *Prompt: type into Claude Code* or *Shell: run
  in your terminal*; use `<placeholders>`, never invented ids or paths; never tell the user to
  type `exit`/`quit`/`stop`.

## claude-sessions internals

`plugins/claude-sessions/scripts/sessions.py` is one file organised as data sources → collect →
filter → output, with argparse subcommands `list` (default), `show`, `copy`, `dump`, `doctor`.
Data sources live under `$CLAUDE_CONFIG_DIR` (default `~/.claude`): per-project transcripts
`projects/<encoded-cwd>/<session-id>.jsonl`, `history.jsonl`, `sessions/<pid>.json`, and
`~/.claude.json`; plus `claude agents --json` for live state. The transcript format is Claude
Code internal and changes between versions: `plugins/claude-sessions/references/session-storage.md`
is the authoritative map and must be updated whenever the parsing changes, because the skills
fall back to it when the script errors. The plugin's own README and CHANGELOG hold the rest.
