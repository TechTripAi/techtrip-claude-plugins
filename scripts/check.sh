#!/usr/bin/env bash
# Repository health check for techtrip-claude-plugins. Read-only; exits non-zero on any failure.
#
# Usage: bash scripts/check.sh
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
fails=0
ok()   { printf 'ok    %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
warn() { printf 'warn  %s\n' "$1"; }

# 1. manifests parse
for f in .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json; do
    if python3 -m json.tool "$f" >/dev/null 2>&1; then ok "json $f"; else fail "json $f"; fi
done

# 2. each plugin: manifest name equals directory; version matches the dev-marketplace entry
for p in plugins/*/; do
    name="$(basename "$p")"; m="$p.claude-plugin/plugin.json"
    [ -f "$m" ] || { fail "$name: no .claude-plugin/plugin.json"; continue; }
    m_name="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "$m")"
    [ "$m_name" = "$name" ] && ok "$name: manifest name matches directory" || fail "$name: manifest name '$m_name' != directory"
    m_ver="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$m")"
    e_ver="$(python3 -c 'import json,sys; d=json.load(open(".claude-plugin/marketplace.json")); print(next((e.get("version","") for e in d["plugins"] if e["name"]==sys.argv[1]), "<no entry>"))' "$name")"
    [ "$m_ver" = "$e_ver" ] && ok "$name: version $m_ver agrees with marketplace entry" || fail "$name: plugin.json $m_ver vs marketplace entry $e_ver"
    [ -f "$p/README.md" ] && ok "$name: README" || fail "$name: no README.md"
    [ -f "$p/CHANGELOG.md" ] && ok "$name: CHANGELOG" || fail "$name: no CHANGELOG.md"
    grep -q "^## \[\?$m_ver" "$p/CHANGELOG.md" 2>/dev/null && ok "$name: CHANGELOG has $m_ver" || warn "$name: CHANGELOG has no heading for $m_ver"
    # skills: frontmatter name equals directory; brain-dump present
    [ -d "$p/skills/brain-dump" ] && ok "$name: brain-dump skill" || fail "$name: no brain-dump skill"
    for s in "$p"skills/*/; do
        sname="$(basename "$s")"; md="$s/SKILL.md"
        [ -f "$md" ] || { fail "$name/$sname: no SKILL.md"; continue; }
        fm="$(awk 'NR>1 && /^---/{exit} /^name:/{sub(/^name:[ \t]*/,""); print}' "$md")"
        [ "$fm" = "$sname" ] && ok "$name/$sname: frontmatter name matches" || fail "$name/$sname: frontmatter name '$fm' != directory"
    done
done

# 3. bundled scripts compile / parse
for f in plugins/*/scripts/*.py; do
    [ -f "$f" ] || continue
    if python3 -m py_compile "$f" 2>/dev/null; then ok "py_compile $f"; else fail "py_compile $f"; fi
done
find plugins -name __pycache__ -type d -prune -exec rm -r {} + 2>/dev/null || true
for f in scripts/*.sh plugins/*/scripts/*.sh; do
    [ -f "$f" ] || continue
    if bash -n "$f" 2>/dev/null; then ok "syntax $f"; else fail "syntax $f"; fi
done

# 4. Claude Code's own validator, if available
if command -v claude >/dev/null 2>&1; then
    if out="$(claude plugin validate . 2>&1)"; then
        if printf '%s' "$out" | grep -q 'warning'; then warn "claude plugin validate passed with warnings"; else ok "claude plugin validate"; fi
    elif [ "$(printf '%s\n' "$out" | grep -c '❯')" -eq "$(printf '%s\n' "$out" | grep -c 'is reserved: it passes as one of Anthropic')" ]; then
        # Known and accepted: plugin names starting with "claude-" predate the reserved-name
        # rule (Claude Code 2.1.3xx). Deferred; see the catalog's ADR-006. Fail on anything else.
        warn "claude plugin validate: only the known reserved-name finding (claude- prefix); accepted for now"
    else fail "claude plugin validate"; printf '%s\n' "$out" | sed 's/^/      /'; fi
else
    warn "claude not on PATH; skipped claude plugin validate"
fi

echo
if [ "$fails" -eq 0 ]; then echo "check: all green"; else echo "check: $fails failure(s)"; exit 1; fi
