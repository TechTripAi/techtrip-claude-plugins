# techtrip-claude-plugins

TechTrip AI's **Claude Code–specific plugins**, one directory each under `plugins/`. These are
small tools that only make sense inside Claude Code (they read its session store, its
settings, its transcripts). Anything that targets other harnesses too (Copilot CLI, Cursor,
Codex, or anything that reads `SKILL.md`) lives in its own repository instead.

Users never add this repository directly. Every TechTrip plugin is installed from the one
public catalog, [TechTrip-AI-plugins](https://github.com/TechTripAi/TechTrip-AI-plugins):

```
/plugin marketplace add TechTripAi/TechTrip-AI-plugins
/plugin install claude-sessions@TechTrip-AI-plugins
/claude-sessions:brain-dump
```

## Plugins in this repository

| Plugin | What it does | Start here |
|---|---|---|
| [claude-sessions](plugins/claude-sessions/) | Find, list, resume and summarize past Claude Code sessions across every project on this machine or just the current directory: directory, session id, status, last active, the last thing you said, and the exact resume command; plus a brief or full summary of any session, on screen or as a markdown file. Flags sessions still running elsewhere so you do not fork them by accident. | `/claude-sessions:brain-dump` |

## How TechTrip repositories are organized

One repository per domain. A Claude-only domain (this one) may hold several plugins under
`plugins/`; the catalog points at each with a `git-subdir` entry. A cross-harness domain is one
plugin at its repository root with many skills, because Copilot CLI reads the same catalog but
cannot point into a subdirectory. The full layout is in the catalog's README.

## Conventions every plugin here follows

- **A `brain-dump` skill.** Menu-driven, re-runnable, teaches rather than does. Skills are
  namespaced by plugin (`/claude-sessions:brain-dump`), so every plugin can use the same name.
- **A worker skill that also triggers on plain language.** Invoke it by name or just ask; the
  description is written so Claude reaches for it when it fits.
- **Standard-library scripts.** Bundled scripts run on the Python or shell that ships with
  macOS. No package installs to use a plugin.
- **Read-only unless the README says otherwise.** A plugin that changes files, settings or
  sessions says so up front and asks before doing it.
- **Complete values.** Session ids, paths and commands are always printed in full, in tables
  too, so whatever you copy works when you paste it. Only descriptive text is trimmed.
- **Advise, never install.** A plugin checks for what it needs and tells you what to install
  for your OS. It does not run installers or package managers on your behalf.
- **Nothing leaves the machine.** Plugins here read local files. Any exception is documented
  in that plugin's README.

## Repository layout

```
.claude-plugin/marketplace.json   development marketplace: one relative entry per plugin
plugins/<name>/
  .claude-plugin/plugin.json      that plugin's name, version and metadata
  README.md · CHANGELOG.md
  scripts/, references/           shared by every skill in the plugin
  skills/<skill>/SKILL.md         invoked as /<plugin>:<skill>
scripts/check.sh                  health check: manifests, frontmatter, versions, scripts
```

## Developing

Register this checkout as a marketplace once; plugins then load in place, and edits apply at
the next session start or after `/reload-plugins`, with no version bump:

```
claude plugin marketplace add /path/to/techtrip-claude-plugins
claude plugin install claude-sessions@techtrip-claude-plugins
```

Do not also install the same plugin from the public catalog on that machine; two copies leave
the bare skill name pointing at whichever loaded first. Run `bash scripts/check.sh` before
every commit.

## Releasing a plugin

1. Bump `version` in `plugins/<name>/.claude-plugin/plugin.json`, add a dated CHANGELOG
   heading, and set the same version on the plugin's entry in this repo's
   `.claude-plugin/marketplace.json`. Run `bash scripts/check.sh`. Commit; the owner pushes.
2. In [TechTrip-AI-plugins](https://github.com/TechTripAi/TechTrip-AI-plugins), set the
   plugin's entry `version` to the same string and push. Users receive the release on their
   next `/plugin marketplace update TechTrip-AI-plugins` + `/plugin update`.

The plugin's `plugin.json` is the version of record; the catalog mirrors it.

## License

[FSL-1.1-MIT](LICENSE.md). Functional Source License: free to use, modify and redistribute
for anything except a competing product, and it converts to MIT two years after each release.

## Credits

Built by [Terry Trippany](https://github.com/TechTripAi) (Try AI Solutions) with Claude Code.
